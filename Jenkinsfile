def secrets = [
  [path: 'secret/jenkins/dockerhub', engineVersion: 2, secretValues: [
    [envVar: 'USERNAME', vaultKey: 'username'],
    [envVar: 'PASSWORD', vaultKey: 'password']]],
]
def configuration = [vaultUrl: 'http://vault:8200',  vaultCredentialId: 'vault', engineVersion: 2]

pipeline {
    agent any
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
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
                sh "docker login -u ${env.USERNAME} -p ${env.PASSWORD}"
                
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
            sh "terraform -v"
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
