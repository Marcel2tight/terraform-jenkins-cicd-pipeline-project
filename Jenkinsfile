def COLOR_MAP = [
    'SUCCESS': 'good',
    'FAILURE': 'danger',
    'UNSTABLE': 'danger',
    'ABORTED': 'warning' // Added ABORTED to handle manual aborts/interrupts gracefully
]

pipeline {
    agent any
    
    // 1. ENVIRONMENT BLOCK: Define secrets and channels securely
    environment {
        // This is the correct channel name we set up
        SLACK_CHANNEL = '#deploy-infra-project' 
        // This MUST match the ID of the secret text credential ('xoxb-') you saved in Jenkins
        SLACK_CREDENTIAL_ID = 'SLACK_BOT_TOKEN' 
    }

    stages {
        // Verifying terraform setup
        stage('Confirm Tools Installations') {
            steps {
                sh 'terraform version'
            }
        }
        // Initialize Terraform
        stage('Initialize Terraform Environment') {
            steps {
                sh 'terraform init'
            }
        }
        // Check terraform configurations syntax
        stage('Validate Terraform Configurations') {
            steps {
                sh 'terraform validate'
            }
        }
        // Generating Execution Plan
        stage('Generate Terraform Plan') {
            steps {
                sh 'terraform plan'
            }
        }
        // Deployment Approval
        stage('Manual Approval') {
            steps {
                input 'Approval Infra Deployment'
            }
        }
        // Deploy Terraform Infrastructure (Uncommented for execution after approval)
        stage('Deploy Infrastructure') {
            steps {
                sh 'terraform apply --auto-approve'
            }
        }
        // Destroy Environment
        stage('Terraform Destroy') {
            steps {
                sh 'terraform destroy --auto-approve'
            }
        }
    }
    
    post {
        // 2. ENSURE NOTIFICATION IS ALWAYS SENT AND CLEANUP OCCURS
        always {
            echo 'Sending Slack Notification...'
            
            // CORRECTED slackSend: Uses environment variables and includes the token ID
            slackSend (
                channel: env.SLACK_CHANNEL, // Uses the dynamic channel name
                tokenCredentialId: env.SLACK_CREDENTIAL_ID, // Securely loads the xoxb- token
                color: COLOR_MAP[currentBuild.currentResult] ?: 'warning',
                message: "*${currentBuild.currentResult}:* Job Name '${env.JOB_NAME}' build ${env.BUILD_NUMBER} \n Build Timestamp: ${env.BUILD_TIMESTAMP} \n Project Workspace: ${env.WORKSPACE} \n More info at: ${env.BUILD_URL}"
            )
            
            // Clean up the workspace files after the build finishes
            cleanWs()
        }
    }
}