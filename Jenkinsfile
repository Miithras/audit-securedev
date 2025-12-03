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
                    // Borramos reportes antiguos si existen
                    sh "rm -f reporte_bandit.json reporte_zap.html"
                }
            }
        }

        stage('Análisis Estático (Bandit)') {
            steps {
                script {
                    echo 'Configurando entorno Python local...'
                    // Instalamos entorno y bandit
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
                    sh "docker network create ${NETWORK_NAME} "
                    // App escuchando en 0.0.0.0
                    sh "docker run -d --name ${CONTAINER_NAME} --network ${NETWORK_NAME} ${IMAGE_NAME}"
                    sleep 10
                }
            }
        }

        stage('Escaneo OWASP ZAP') {
            steps {
                script {
                    // CAMBIO CLAVE AQUÍ:
                    // 1. Damos permiso total (777) a TODA la carpeta actual (pwd)
                    //    Esto permite que el usuario 'zap' cree archivos donde quiera.
                    sh "chmod -R 777 ."
                    
                    echo 'Iniciando ataque con OWASP ZAP...'
                    sh """
                    docker run --rm --network ${NETWORK_NAME} \
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
            // Recolectamos la evidencia
            archiveArtifacts artifacts: 'reporte_bandit.json, reporte_zap.html', allowEmptyArchive: true
            
            script {
                sh "docker rm -f ${CONTAINER_NAME} || true"
                sh "docker network rm ${NETWORK_NAME} || true"
                sh "rm -rf venv"
            }
        }
    }
}