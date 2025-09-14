pipeline{
    agent any
    stages {
        stage('Checkout git'){
            steps {
                git url: 'https://github.com/zerajudeen-zera/Trendsapp.git', branch: 'main'
            }

        }
        stage('Build Docker Image'){
            steps {
                sh 'echo "Building Docker Image..."'
                sh 'docker build -t zera18/trendsapp:latest .'
            }

        }
        stage('Push Image to Docker Hub registry'){
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker_hub', passwordVariable: 'DOCKERHUB_PASSWORD', usernameVariable: 'DOCKERHUB_USERNAME')]) {
                    sh 'echo $DOCKERHUB_PASSWORD | docker login -u $DOCKERHUB_USERNAME --password-stdin'
                    sh 'docker push zera18/trendsapp:latest'
                }
            }
        }
        stage('Deploy to EKS cluster'){
            steps {
                sh 'echo "Deploying to EKS cluster..."'
                sh 'aws eks update-kubeconfig --region ap-south-1 --name trendsapp-cluster2'
                sh 'kubectl apply -f deployment.yaml --validate=false'
                sh 'kubectl apply -f service.yaml'
            }
        }
        
    }
    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Please check the logs.'

        } 
    }
}