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

        // ADD THE RESOURCE CHECK STAGE HERE
        stage('Check If Resources Exist') {
            steps {
                withCredentials([file(credentialsId: env.GCP_CREDENTIAL_ID, variable: 'GCP_KEY_FILE')]) {
                    script {
                        sh '''
                            export GOOGLE_APPLICATION_CREDENTIALS="$GCP_KEY_FILE"
                        '''
                        try {
                            sh '''
                                gcloud compute instances describe terraform-vm --zone=us-central1-b > /dev/null 2>&1
                                echo "⚠️  Resources already exist - will skip create and proceed to destroy"
                            '''
                            env.SKIP_CREATE = "true"
                        } catch (Exception e) {
                            echo "✅ Resources don't exist - proceeding with normal create/destroy flow"
                            env.SKIP_CREATE = "false"
                        }
                    }
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
            when {
                expression { env.SKIP_CREATE == "false" }
            }
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
            when {
                expression { env.SKIP_CREATE == "false" }
            }
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
            when {
                expression { env.SKIP_CREATE == "false" }
            }
            steps {
                input message: 'Approve Infrastructure DEPLOYMENT?', 
                      ok: 'Deploy',
                      submitterParameter: 'approver'
            }
        }

        stage('Deploy Infrastructure') {
            when {
                expression { env.SKIP_CREATE == "false" }
            }
            steps {
                withCredentials([file(credentialsId: env.GCP_CREDENTIAL_ID, variable: 'GCP_KEY_FILE')]) {
                    sh '''
                        export GOOGLE_APPLICATION_CREDENTIALS="$GCP_KEY_FILE"
                        terraform apply --auto-approve
                    '''
                }
            }
        }

        // ALWAYS show destroy stages, but skip if nothing was created
        stage('Manual Approval - DESTROY') {
            steps {
                script {
                    if (env.SKIP_CREATE == "true") {
                        echo "🚨 DESTROY ONLY MODE: Resources already exist from previous run"
                    }
                }
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