pipeline {
    agent any

    environment {
        AWS_ACCOUNT_ID = "089959488660"
        AWS_REGION = "us-east-1"
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        BACKEND_IMAGE_NAME = "calcify-ai/backend"
        FRONTEND_IMAGE_NAME = "calcify-ai/frontend"
        BACKEND_IMAGE_TAG = "${BUILD_ID}"
        FRONTEND_IMAGE_TAG = "${BUILD_ID}"
        EKS_CLUSTER_NAME = "calcify-Ai-cluster"
        KUBECONFIG = "${WORKSPACE}/.kube/config"
    }

    stages {
        stage('Checkout') {
            steps {
                echo "🔄 Checking out code..."
                checkout scm
            }
        }

        stage('Build Backend') {
            steps {
                echo "🏗️ Building backend Docker image..."
                dir('backend') {
                    script {
                        sh '''
                            docker build -t ${ECR_REGISTRY}/${BACKEND_IMAGE_NAME}:${BACKEND_IMAGE_TAG} \
                                         -t ${ECR_REGISTRY}/${BACKEND_IMAGE_NAME}:latest .
                        '''
                    }
                }
            }
        }

        stage('Build Frontend') {
            steps {
                echo "🏗️ Building frontend Docker image..."
                dir('frontend') {
                    script {
                        sh '''
                            docker build -t ${ECR_REGISTRY}/${FRONTEND_IMAGE_NAME}:${FRONTEND_IMAGE_TAG} \
                                         -t ${ECR_REGISTRY}/${FRONTEND_IMAGE_NAME}:latest .
                        '''
                    }
                }
            }
        }

        stage('Test Backend') {
            steps {
                echo "🧪 Testing backend..."
                dir('backend') {
                    script {
                        sh '''
                            docker run --rm ${ECR_REGISTRY}/${BACKEND_IMAGE_NAME}:${BACKEND_IMAGE_TAG} \
                                python -m pytest . || true
                        '''
                    }
                }
            }
        }

        stage('Scan Images') {
            steps {
                echo "🔍 Scanning Docker images for vulnerabilities..."
                script {
                    sh '''
                        # Install trivy for image scanning (if not present)
                        which trivy || (curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin)
                        
                        trivy image --severity HIGH,CRITICAL ${ECR_REGISTRY}/${BACKEND_IMAGE_NAME}:${BACKEND_IMAGE_TAG} || true
                        trivy image --severity HIGH,CRITICAL ${ECR_REGISTRY}/${FRONTEND_IMAGE_NAME}:${FRONTEND_IMAGE_TAG} || true
                    '''
                }
            }
        }

        stage('Push to ECR') {
            steps {
                echo "📤 Pushing images to ECR..."
                script {
                    sh '''
                        # Login to ECR
                        aws ecr get-login-password --region ${AWS_REGION} | \
                            docker login --username AWS --password-stdin ${ECR_REGISTRY}

                        # Create ECR repositories if they don't exist
                        aws ecr create-repository --repository-name ${BACKEND_IMAGE_NAME} \
                            --region ${AWS_REGION} 2>/dev/null || true
                        aws ecr create-repository --repository-name ${FRONTEND_IMAGE_NAME} \
                            --region ${AWS_REGION} 2>/dev/null || true

                        # Push images
                        docker push ${ECR_REGISTRY}/${BACKEND_IMAGE_NAME}:${BACKEND_IMAGE_TAG}
                        docker push ${ECR_REGISTRY}/${BACKEND_IMAGE_NAME}:latest
                        docker push ${ECR_REGISTRY}/${FRONTEND_IMAGE_NAME}:${FRONTEND_IMAGE_TAG}
                        docker push ${ECR_REGISTRY}/${FRONTEND_IMAGE_NAME}:latest
                    '''
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                echo "🚀 Deploying to EKS..."
                script {
                    sh '''
                        # Configure kubectl for EKS
                        aws eks update-kubeconfig --name ${EKS_CLUSTER_NAME} --region ${AWS_REGION}

                        # Update image tags in manifests
                        sed -i "s|IMAGE_TAG|${BACKEND_IMAGE_TAG}|g" k8s/backend-deployment.yaml
                        sed -i "s|IMAGE_TAG|${FRONTEND_IMAGE_TAG}|g" k8s/frontend-deployment.yaml
                        sed -i "s|ECR_REGISTRY|${ECR_REGISTRY}|g" k8s/backend-deployment.yaml
                        sed -i "s|ECR_REGISTRY|${ECR_REGISTRY}|g" k8s/frontend-deployment.yaml

                        # Create/Update namespace
                        kubectl create namespace calcify-ai --dry-run=client -o yaml | kubectl apply -f -

                        # Apply configurations
                        kubectl apply -f k8s/backend-configmap.yaml -n calcify-ai
                        kubectl apply -f k8s/backend-secret.yaml -n calcify-ai || true

                        # Deploy applications
                        kubectl apply -f k8s/backend-deployment.yaml -n calcify-ai
                        kubectl apply -f k8s/backend-service.yaml -n calcify-ai
                        kubectl apply -f k8s/frontend-deployment.yaml -n calcify-ai
                        kubectl apply -f k8s/frontend-service.yaml -n calcify-ai

                        # Wait for rollout
                        kubectl rollout status deployment/backend -n calcify-ai --timeout=5m
                        kubectl rollout status deployment/frontend -n calcify-ai --timeout=5m
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                echo "✅ Verifying deployment..."
                script {
                    sh '''
                        kubectl get pods -n calcify-ai
                        kubectl get services -n calcify-ai
                        kubectl get deployments -n calcify-ai
                    '''
                }
            }
        }
    }

    post {
        always {
            echo "Cleaning up Docker images..."
            sh 'docker rmi ${ECR_REGISTRY}/${BACKEND_IMAGE_NAME}:${BACKEND_IMAGE_TAG} || true'
            sh 'docker rmi ${ECR_REGISTRY}/${FRONTEND_IMAGE_NAME}:${FRONTEND_IMAGE_TAG} || true'
        }
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed. Check logs above."
        }
    }
}
