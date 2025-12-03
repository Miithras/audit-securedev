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
                    sh "rm -f reporte_bandit.json reporte_zap.html"
                }
            }
        }

        stage('Análisis Estático (Bandit)') {
            steps {
                script {
                    echo 'Configurando entorno Python local...'
                    sh """
                        python3 -m venv venv
                        . venv/bin/activate
                        pip install bandit
                        echo "Ejecutando Bandit..."
                        bandit -r . -f json -o reporte_bandit.json || true
                    """
                }
            }
        }

        stage('Construir y Desplegar') {
            steps {
                script {
                    sh "docker build -t ${IMAGE_NAME} ."
                    sh "docker network create ${NETWORK_NAME}"
                    sh "docker run -d --name ${CONTAINER_NAME} --network ${NETWORK_NAME} ${IMAGE_NAME}"
                    sleep 10
                }
            }
        }

        stage('Escaneo OWASP ZAP') {
            steps {
                script {
                    echo 'Iniciando ataque con OWASP ZAP...'
                    // SOLUCION FINAL: Agregamos "-u 0" para correr como root y evitar AccessDenied
                    sh """
                    docker run --rm --network ${NETWORK_NAME} -u 0 \
                    -v \$(pwd):/zap/wrk/:rw \
                    ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
                    -t http://${CONTAINER_NAME}:5000 \
                    -r reporte_zap.html \
                    -I || true
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
                sh "rm -rf venv"
            }
        }
    }
}