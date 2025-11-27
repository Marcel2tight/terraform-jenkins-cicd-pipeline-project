def COLOR_MAP = [
    'SUCCESS': 'good',
    'FAILURE': 'danger',
    'UNSTABLE': 'danger',
    'ABORTED': 'warning'
]

pipeline {
    agent any
    
    environment {
        SLACK_CHANNEL = '#deploy-infra-project' 
        SLACK_CREDENTIAL_ID = 'SLACK_BOT_TOKEN'
        GCP_CREDENTIAL_ID = 'gcp-jenkins-terraform'
    }

    stages {
        stage('Clean Terraform State') {
            steps {
                sh '''
                    echo "🧹 Cleaning previous Terraform state only"
                    rm -rf .terraform
                    rm -f *.tfstate*
                    echo "✅ Configuration files present:"
                    ls -la *.tf
                '''
            }
        }

        stage('GCP Authentication') {
            steps {
                withCredentials([file(credentialsId: env.GCP_CREDENTIAL_ID, variable: 'GCP_KEY_FILE')]) {
                    sh '''
                        export GOOGLE_APPLICATION_CREDENTIALS="$GCP_KEY_FILE"
                        echo "Authenticated as: $(cat $GCP_KEY_FILE | jq -r '.client_email')"
                    '''
                }
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([file(credentialsId: env.GCP_CREDENTIAL_ID, variable: 'GCP_KEY_FILE')]) {
                    sh '''
                        export GOOGLE_APPLICATION_CREDENTIALS="$GCP_KEY_FILE"
                        terraform init
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([file(credentialsId: env.GCP_CREDENTIAL_ID, variable: 'GCP_KEY_FILE')]) {
                    sh '''
                        export GOOGLE_APPLICATION_CREDENTIALS="$GCP_KEY_FILE"
                        terraform plan
                    '''
                }
            }
        }

        stage('Manual Approval - DEPLOY') {
            steps {
                input 'Approve Deployment?'
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([file(credentialsId: env.GCP_CREDENTIAL_ID, variable: 'GCP_KEY_FILE')]) {
                    sh '''
                        export GOOGLE_APPLICATION_CREDENTIALS="$GCP_KEY_FILE"
                        terraform apply -auto-approve
                    '''
                }
            }
        }

        stage('Manual Approval - DESTROY') {
            steps {
                input 'Approve Destruction?'
            }
        }

        stage('Terraform Destroy') {
            steps {
                withCredentials([file(credentialsId: env.GCP_CREDENTIAL_ID, variable: 'GCP_KEY_FILE')]) {
                    sh '''
                        export GOOGLE_APPLICATION_CREDENTIALS="$GCP_KEY_FILE"
                        terraform destroy -auto-approve
                    '''
                }
            }
        }
    }
    
    post {
        always {
            slackSend (
                channel: env.SLACK_CHANNEL,
                tokenCredentialId: env.SLACK_CREDENTIAL_ID,
                color: COLOR_MAP[currentBuild.currentResult] ?: 'warning',
                message: "*${currentBuild.currentResult}:* ${env.JOB_NAME} #${env.BUILD_NUMBER}"
            )
        }
    }
}