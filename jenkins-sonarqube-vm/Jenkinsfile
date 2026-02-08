pipeline {
    agent any

    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout from Git') {
            steps {
                git branch: 'main', url: 'https://github.com/anshumanhota1/youtube-clone-app.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube-Server') {
                    sh """
                        $SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectName=Youtube-CICD \
                        -Dsonar.projectKey=Youtube-CICD
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'SonarQube-Token'
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }

        stage('TRIVY FS Scan') {
            steps {
                sh 'trivy fs . > trivyfs.txt'
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'dockerhub', toolName: 'docker') {   
                        sh 'docker build -t youtube-clone .'
                        sh 'docker tag youtube-clone 2swapna/youtube-clone:latest'
                        sh 'docker push 2swapna/youtube-clone:latest'
                    }
                }
            }
        }

        stage('TRIVY Image Scan') {
            steps {
                sh 'trivy image 2swapna/youtube-clone:latest > trivyimage.txt'
            }
        }

        // Uncomment and configure this block when deploying to Kubernetes

        stage('Deploy to Kubernetes') {
            steps {
                script {
                            sh 'kubectl delete --all pods'
                            sh 'kubectl apply -f deployment.yml'
                            sh 'kubectl apply -f service.yml'
                        }
                    }
                }
            }
   

    post {
        always {
            emailext(
                attachLog: true,
                subject: "'${currentBuild.result}'",
                body: """Project: ${env.JOB_NAME}<br/>
                         Build Number: ${env.BUILD_NUMBER}<br/>
                         URL: ${env.BUILD_URL}<br/>""",
                to: '2swapna69@gmail.com',
                attachmentsPattern: 'trivyfs.txt,trivyimage.txt'
            )
        }
    }
}

