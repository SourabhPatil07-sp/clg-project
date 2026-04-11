pipeline {
    agent any
    
    parameters {
        string(name: 'ECR_REPO_NAME', defaultValue: 'patil', description: 'Enter repository name')
        string(name: 'AWS_ACCOUNT_ID', defaultValue: '089959488660', description: 'Enter AWS Account ID') // Added missing quote
    }
    
    tools {
        jdk 'JDK'
        nodejs 'NodeJS'
    }
    
    environment {
        SCANNER_HOME = tool 'SonarQube Scanner'
    }
    
    stages {
        stage('1. Git Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/SourabhPatil07-sp/clg-project.git'
            }
        }
        
          
        stage('2. Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }
        
        stage('3. SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh """
                    $SCANNER_HOME/bin/sonar-scanner \
                    -Dsonar.projectName=patil \
                    -Dsonar.projectKey=patil
                    """
                }
            }
        }
        
        stage('4. Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        stage('5. Trivy Scan') {
            steps {
                sh "trivy fs . > trivy-report.txt || true"
            }
        }
        
        stage('6. Build Docker Image') {
            steps {
                sh "docker build -t ${params.ECR_REPO_NAME}:${BUILD_NUMBER} ."
            }
        }
        
        stage('7. Create ECR Repository') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-credentials'
                ]]) {
                    sh """
                    aws ecr describe-repositories \
                    --repository-names ${params.ECR_REPO_NAME} \
                    --region $AWS_REGION || \
                    aws ecr create-repository \
                    --repository-name ${params.ECR_REPO_NAME} \
                    --region $AWS_REGION
                    """
                }
            }
        }
        
        stage('8. Login to ECR') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-credentials'
                ]]) {
                    sh """
                    aws ecr get-login-password --region $AWS_REGION | \
                    docker login --username AWS --password-stdin \
                    ${params.AWS_ACCOUNT_ID}.dkr.ecr.$AWS_REGION.amazonaws.com
                    """
                }
            }
        }
        
        stage('9. Tag Docker Image') {
            steps {
                sh """
                docker tag ${params.ECR_REPO_NAME}:${BUILD_NUMBER} \
                ${params.AWS_ACCOUNT_ID}.dkr.ecr.$AWS_REGION.amazonaws.com/${params.ECR_REPO_NAME}:${BUILD_NUMBER}
                
                docker tag ${params.ECR_REPO_NAME}:${BUILD_NUMBER} \
                ${params.AWS_ACCOUNT_ID}.dkr.ecr.$AWS_REGION.amazonaws.com/${params.ECR_REPO_NAME}:latest
                """
            }
        }
        
        stage('10. Push to ECR') {
            steps {
                sh """
                docker push ${params.AWS_ACCOUNT_ID}.dkr.ecr.$AWS_REGION.amazonaws.com/${params.ECR_REPO_NAME}:${BUILD_NUMBER}
                docker push ${params.AWS_ACCOUNT_ID}.dkr.ecr.$AWS_REGION.amazonaws.com/${params.ECR_REPO_NAME}:latest
                """
            }
        }
        
        stage('11. Cleanup') {
            steps {
                sh """
                docker rmi ${params.ECR_REPO_NAME}:${BUILD_NUMBER} || true
                docker rmi ${params.AWS_ACCOUNT_ID}.dkr.ecr.$AWS_REGION.amazonaws.com/${params.ECR_REPO_NAME}:${BUILD_NUMBER} || true
                docker rmi ${params.AWS_ACCOUNT_ID}.dkr.ecr.$AWS_REGION.amazonaws.com/${params.ECR_REPO_NAME}:latest || true
                """
            }
        }
    }
    
    post {
        success {
            echo "✅ CI Pipeline Completed Successfully!"
        }
        failure {
            echo "❌ Pipeline Failed!"
        }
    }
}
