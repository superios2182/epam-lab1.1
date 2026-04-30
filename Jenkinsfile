pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                // Дженкинс сам скачает код из GitHub на этом этапе
                echo 'Стягиваем код из репозитория...'
            }
        }

        stage('Deploy to AWS S3') {
            steps {
                echo 'Начинаем копирование файла на S3...'
                // Та самая команда, которую мы раньше писали в окошке
                sh 'aws s3 cp index.html s3://mirza-jenkins-lab1.1'
            }
        }
    }
}
