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
        stage('GCP Authentication') {
            steps {
                withCredentials([file(credentialsId: env.GCP_CREDENTIAL_ID, variable: 'GCP_KEY_FILE')]) {
                    sh '''
                        echo "Setting up GCP authentication..."
                        export GOOGLE_APPLICATION_CREDENTIALS="$GCP_KEY_FILE"
                        echo "Service account: $(cat $GCP_KEY_FILE | jq -r '.client_email')"
                        echo "Authentication configured successfully"
                    '''
                }
            }
        }

        stage('Confirm Tools Installations') {
            steps {
                sh 'terraform version'
            }
        }

        stage('Initialize Terraform Environment') {
            steps {
                withCredentials([file(credentialsId: env.GCP_CREDENTIAL_ID, variable: 'GCP_KEY_FILE')]) {
                    sh '''
                        export GOOGLE_APPLICATION_CREDENTIALS="$GCP_KEY_FILE"
                        terraform init
                    '''
                }
            }
        }

        stage('Validate Terraform Configurations') {
            steps {
                withCredentials([file(credentialsId: env.GCP_CREDENTIAL_ID, variable: 'GCP_KEY_FILE')]) {
                    sh '''
                        export GOOGLE_APPLICATION_CREDENTIALS="$GCP_KEY_FILE"
                        terraform validate
                    '''
                }
            }
        }

        stage('Generate Terraform Plan') {
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
                input message: 'Approve Infrastructure DEPLOYMENT?', 
                      ok: 'Deploy',
                      submitterParameter: 'approver'
            }
        }

        stage('Deploy Infrastructure') {
            steps {
                withCredentials([file(credentialsId: env.GCP_CREDENTIAL_ID, variable: 'GCP_KEY_FILE')]) {
                    sh '''
                        export GOOGLE_APPLICATION_CREDENTIALS="$GCP_KEY_FILE"
                        terraform apply --auto-approve
                    '''
                }
            }
        }

        // DESTROY with safety approvals
        stage('Manual Approval - DESTROY') {
            steps {
                input message: '🚨 DANGER: Approve Infrastructure DESTRUCTION? This will DELETE all resources!', 
                      ok: 'DESTROY',
                      submitterParameter: 'destroy_approver'
            }
        }

        stage('Terraform Destroy') {
            steps {
                withCredentials([file(credentialsId: env.GCP_CREDENTIAL_ID, variable: 'GCP_KEY_FILE')]) {
                    sh '''
                        export GOOGLE_APPLICATION_CREDENTIALS="$GCP_KEY_FILE"
                        terraform destroy --auto-approve
                    '''
                }
            }
        }
    }
    
    post {
        always {
            echo 'Sending Slack Notification...'
            slackSend (
                channel: env.SLACK_CHANNEL,
                tokenCredentialId: env.SLACK_CREDENTIAL_ID,
                color: COLOR_MAP[currentBuild.currentResult] ?: 'warning',
                message: "*${currentBuild.currentResult}:* Job Name '${env.JOB_NAME}' build ${env.BUILD_NUMBER} \n More info at: ${env.BUILD_URL}"
            )
            cleanWs()
        }
    }
}