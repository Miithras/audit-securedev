pipeline {
    agent any

    environment {
        IMAGE_NAME = "vulnerable-flask-app"
        CONTAINER_NAME = "vulnerable-app-instance"
        NETWORK_NAME = "audit-net"
    }

    stages {
        stage('Limpieza Inicial') {
            steps {
                script {
                    sh "docker rm -f ${CONTAINER_NAME} || true"
                    sh "docker network rm ${NETWORK_NAME} || true"
                }
            }
        }

        stage('Análisis Estático (Bandit)') {
            steps {
                script {
                    echo 'Ejecutando Bandit localmente...'
                    // Ahora corremos bandit directamente, sin docker run
                    sh "bandit -r . -f json -o reporte_bandit.json || true"
                }
            }
        }

        stage('Construir y Desplegar') {
            steps {
                script {
                    sh "docker build -t ${IMAGE_NAME} ."
                    sh "docker network create ${NETWORK_NAME}"
                    // Ejecutamos la app. GRACIAS AL CAMBIO 0.0.0.0 AHORA SERÁ VISIBLE
                    sh "docker run -d --name ${CONTAINER_NAME} --network ${NETWORK_NAME} ${IMAGE_NAME}"
                    sleep 10
                }
            }
        }

        stage('Escaneo OWASP ZAP') {
            steps {
                script {
                    // Damos permisos a la carpeta para que Docker pueda escribir el reporte
                    sh "chmod 777 \$(pwd)"
                    
                    echo 'Iniciando ataque con OWASP ZAP...'
                    sh """
                    docker run --rm --network ${NETWORK_NAME} \
                    -v \$(pwd):/zap/wrk/:rw \
                    ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
                    -t http://${CONTAINER_NAME}:5000 \
                    -r reporte_zap.html || true
                    """
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'reporte_bandit.json, reporte_zap.html', allowEmptyArchive: true
            script {
                sh "docker rm -f ${CONTAINER_NAME} || true"
                sh "docker network rm ${NETWORK_NAME} || true"
            }
        }
    }
}