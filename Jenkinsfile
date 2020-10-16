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

     parameters {
        string(name: 'WORKSPACE', defaultValue: 'development', description:'setting up workspace for terraform')
    }

     environment {
        TF_HOME = tool('terraform')
        TF_IN_AUTOMATION = "true"
        PATH = "$TF_HOME:$PATH"
    }
  
    triggers {
      pollSCM('H/5 * * * *') 
    }
    stages {
        stage('Test') {
             agent {
             docker { image 'maven:3.6-openjdk-16'
                      args '-v $HOME/.m2:/root/.m2'
                      }
            }
            steps {
                // Get some code from a GitHub repository
                git branch: "main", url: 'https://github.com/Kostua/spring-petclinic'

                // Run Maven make package and stash artifact with name "app" 
                sh "mvn -Dmaven.test.failure.ignore=true -Dcheckstyle.skip package"
                stash includes: '**/target/*.jar', name: 'app'

            }
        }
        stage('Build image'){
          agent any
          steps {
                // Unstash artifact from pervious stage and build docker image
                unstash 'app'
                sh "docker build -t kostua/petclinic:latest ."
          }

        }

        stage('Docker login') {
          agent any
           steps {
                // Login to DockerHub with credential from Vault
                withVault([configuration: configuration, vaultSecrets: secrets]) {
                sh "docker login -u ${env.GITHUB_USERNAME} -p ${env.GITHUB_PASSWORD}"
                
                }
            }

        }
        
        stage('Docker push') {
            steps {
                sh "docker push kostua/petclinic:latest"
            }
        }

        stage('Terraforn Init') {
          steps {
                withVault([configuration: configuration, vaultSecrets: secrets]){ 
                dir('deploy/AWS/Terraform/live/dev'){
                    sh "terraform init -input=false -var 'access_key=${env.AWS_ACCESS_KEY_ID}' -var 'secret_key=${env.AWS_SECRET_ACCESS_KEY}'"
                  
                }
              }
          }
        }

        stage('Terraform Validate'){
            steps {
                dir('deploy/AWS/Terraform/live/dev'){
                    sh "terraform validate"
                }
            }
        }

        stage('Terraform Plan'){
            steps {
              withVault([configuration: configuration, vaultSecrets: secrets]){
                dir('deploy/AWS/Terraform/live/dev'){
                    
                  sh "terraform plan -var 'access_key=${env.AWS_ACCESS_KEY_ID}' -var 'secret_key=${env.AWS_SECRET_ACCESS_KEY}' \
                        -out terraform.tfplan;echo \$? > status"
                  stash name: "terraform-plan", includes: "terraform.tfplan"
                    
                }
              }
            }
           }

        
        


  }  
    post {
        always {
            echo 'One way or another, I have finished'
            deleteDir() /* clean up our workspace */
      }
    }
}
