def secrets = [
  [path: 'secret/jenkins/dockerhub', engineVersion: 2, secretValues: [
    [envVar: 'GITHUB_USERNAME', vaultKey: 'username'],
    [envVar: 'GITHUB_PASSWORD', vaultKey: 'password']]],
  
  [path: 'secret/jenkins/aws', engineVersion: 2, secretValues: [
    [envVar: 'AWS_ACCESS_KEY_ID', vaultKey: 'access_key'],
    [envVar: 'AWS_SECRET_ACCESS_KEY', vaultKey: 'secret_key']]],

]
def configuration = [vaultUrl: 'http://vault:8200',  vaultCredentialId: 'vault', engineVersion: 2]

pipeline {
    agent any
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
    }

     environment {
        ORG_NAME = "kostua"
        APP_NAME = "petclinic"
        TF_IN_AUTOMATION = "true"
        PATH = "$TF_HOME:$PATH"
        
    }
  
    triggers {
      pollSCM('H/5 * * * *') 
    }
    stages {
        stage('Unit tests') {
             agent {
             docker { image 'adoptopenjdk/openjdk8:jdk8u232-b09-debian'
                      args '-v $HOME/.m2:/root/.m2'
                      }
            }
            steps {
                // Get some code from a GitHub repository
                git branch: "main", url: 'https://github.com/Kostua/spring-petclinic'

                // Run Maven make package and stash artifact with name "app" 
                //sh "mvn -Dmaven.test.failure.ignore=true -Dcheckstyle.skip package"
                sh "./mvnw -Dcheckstyle.skip package"
                sh "./mvnw -Dcheckstyle.skip test"
                publishHTML (target: [
                    reportDir: 'target/site/jacoco/', reportFiles: 'index.html',
                    reportName: "JaCoCo Report"
                ])

                stash includes: '**/target/*.jar', name: 'app'

            }
        }

        stage('Docker') {
          agent any
           steps {
                // Login to DockerHub with credential from Vault
                withVault([configuration: configuration, vaultSecrets: secrets]) {
                unstash 'app'
                sh "docker build -t ${ORG_NAME}/${APP_NAME}:latest ."
                sh "docker login -u ${env.GITHUB_USERNAME} -p ${env.GITHUB_PASSWORD}"
                sh "docker push ${ORG_NAME}/${APP_NAME}:latest"
                }
            }

        }

        stage('Terraform Init/Valitade/Plan DEV') {
          when {
                branch 'development'
            }
          steps {
                withVault([configuration: configuration, vaultSecrets: secrets]){ 
                dir('deploy/aws/terraform/live/dev'){
                    sh "terraform init -backend-config=backend.hcl -input=false"
                    sh "terraform validate"
                    sh "terraform plan -out terraform.tfplan"
                    stash name: "terraform-plan", includes: "terraform.tfplan"
                }
              }
          }
        }

           stage('Terraform Apply DEV'){
             when {
                branch 'development'
            }
            steps {
              withVault([configuration: configuration, vaultSecrets: secrets]){
                script{
                    def apply = false
                    try {
                        input message: 'Can you please confirm the apply', ok: 'Ready to Apply the Config'
                        apply = true
                    } catch (err) {
                        apply = false
                         currentBuild.result = 'UNSTABLE'
                    }
                    if(apply){
                        dir('deploy/aws/terraform/live/dev'){
                            unstash "terraform-plan"
                            sh 'terraform apply -input=false -auto-approve terraform.tfplan'
                        }
                    }
                }
            }
        }
     }
          stage('Sanity check DEV'){
            when {
                branch 'development'
            }
            steps {
              withVault([configuration: configuration, vaultSecrets: secrets]){
                 dir('deploy/aws/terraform/live/dev'){
                  input "Does the staging environment look ok?"
                  sh 'terraform destroy -input=false -auto-approve'
                 }
              }
            }
          }
      
       stage('Terraform Init/Valitade/Plan PROD') {
            when {
                branch 'main'
            }
          steps {
                withVault([configuration: configuration, vaultSecrets: secrets]){ 
                dir('deploy/aws/terraform/live/prod'){
                    input "If dev env looks good deploy to PROD?"
                    sh "terraform init -backend-config=backend.hcl -input=false"
                    sh "terraform validate"
                    sh "terraform plan -out terraform.tfplan"
                    stash name: "terraform-plan", includes: "terraform.tfplan"
                }
              }
          }
        }

       stage('Terraform Apply PROD'){
            when {
                branch 'main'
            }
            steps {
              withVault([configuration: configuration, vaultSecrets: secrets]){
                script{
                    def apply = false
                    try {
                        input message: 'Can you please confirm the apply to PROD?', ok: 'Ready to Apply the Config'
                        apply = true
                    } catch (err) {
                        apply = false
                         currentBuild.result = 'UNSTABLE'
                    }
                    if(apply){
                        dir('deploy/aws/terraform/live/prod'){
                            unstash "terraform-plan"
                            sh 'terraform apply -input=false -auto-approve terraform.tfplan'
                        }
                    }
                }
            }
        }
     }
    
  }  
    post {
        always {
            echo 'Clean up workspace'
            deleteDir() /* clean up our workspace */
      }
    }
}
