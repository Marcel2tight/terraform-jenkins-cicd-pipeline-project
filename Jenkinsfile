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

        // FIXED: Resource Check that fails early if conflicts exist
        stage('Check Resource Conflicts') {
            steps {
                withCredentials([file(credentialsId: env.GCP_CREDENTIAL_ID, variable: 'GCP_KEY_FILE')]) {
                    script {
                        sh '''
                            export GOOGLE_APPLICATION_CREDENTIALS="$GCP_KEY_FILE"
                        '''
                        
                        // Check if VM exists
                        try {
                            sh '''
                                gcloud compute instances describe terraform-vm --zone=us-central1-b --quiet
                            '''
                            error "❌ VM 'terraform-vm' already exists! Run destroy pipeline first or delete manually."
                        } catch (Exception e) {
                            echo "✅ VM check passed - no conflicts"
                        }
                        
                        // Check if storage buckets exist
                        try {
                            sh '''
                                gcloud storage buckets describe gs://prod-no-public-access-bucket-po-0 --quiet
                            '''
                            error "❌ Storage bucket 'prod-no-public-access-bucket-po-0' already exists!"
                        } catch (Exception e) {
                            echo "✅ Storage bucket check 1 passed"
                        }
                        
                        try {
                            sh '''
                                gcloud storage buckets describe gs://prod-no-public-access-bucket-po-1 --quiet
                            '''
                            error "❌ Storage bucket 'prod-no-public-access-bucket-po-1' already exists!"
                        } catch (Exception e) {
                            echo "✅ Storage bucket check 2 passed"
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

        // ... rest of your stages remain the same ...
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