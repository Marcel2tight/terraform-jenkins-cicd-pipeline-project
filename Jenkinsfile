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

        stage('Check and Import Existing Resources') {
            steps {
                withCredentials([file(credentialsId: env.GCP_CREDENTIAL_ID, variable: 'GCP_KEY_FILE')]) {
                    script {
                        sh '''
                            export GOOGLE_APPLICATION_CREDENTIALS="$GCP_KEY_FILE"
                        '''
                        
                        // Check if VM exists but isn't in state
                        try {
                            sh '''
                                gcloud compute instances describe terraform-vm --zone=us-central1-b --quiet
                                echo "⚠️ VM exists but may not be in Terraform state"
                                terraform import google_compute_instance.terraform-vm-instance projects/quixotic-sunset-479410-d5/zones/us-central1-b/instances/terraform-vm || echo "Import failed or already imported"
                            '''
                        } catch (Exception e) {
                            echo "✅ VM doesn't exist or already in state"
                        }
                        
                        // Check if buckets exist but aren't in state
                        try {
                            sh '''
                                gcloud storage buckets describe gs://prod-no-public-access-bucket-po-0 --quiet
                                echo "⚠️ Bucket 0 exists but may not be in Terraform state"
                                terraform import google_storage_bucket.prod-private-buckets[0] prod-no-public-access-bucket-po-0 || echo "Import failed or already imported"
                            '''
                        } catch (Exception e) {
                            echo "✅ Bucket 0 doesn't exist or already in state"
                        }
                        
                        try {
                            sh '''
                                gcloud storage buckets describe gs://prod-no-public-access-bucket-po-1 --quiet
                                echo "⚠️ Bucket 1 exists but may not be in Terraform state"
                                terraform import google_storage_bucket.prod-private-buckets[1] prod-no-public-access-bucket-po-1 || echo "Import failed or already imported"
                            '''
                        } catch (Exception e) {
                            echo "✅ Bucket 1 doesn't exist or already in state"
                        }
                    }
                }
            }
        }

        // TERRAFORM PLAN STAGE GOES HERE
        stage('Terraform Plan') {
            steps {
                withCredentials([file(credentialsId: env.GCP_CREDENTIAL_ID, variable: 'GCP_KEY_FILE')]) {
                    sh '''
                        export GOOGLE_APPLICATION_CREDENTIALS="$GCP_KEY_FILE"
                        terraform plan
                        
                        # If plan shows resource replacement, it's likely a config mismatch
                        echo "⚠️  If you see resource replacement, check zone/region configuration"
                    '''
                }
            }
        }

        stage('Manual Approval - DEPLOY') {
            steps {
                input message: 'Approve Infrastructure DEPLOYMENT?', 
                      ok: 'Deploy'
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
                input message: 'Approve Infrastructure DESTRUCTION?', 
                      ok: 'Destroy'
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