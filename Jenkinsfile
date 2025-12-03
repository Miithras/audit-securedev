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
                    // Limpiamos archivos viejos si existen
                    sh "rm -f reporte_bandit.json reporte_zap.html"
                }
            }
        }

        stage('Análisis Estático (Bandit)') {
            steps {
                script {
                    echo 'Configurando entorno Python local...'
                    // SOLUCIÓN BANDIT: Creamos un entorno virtual dentro del workspace.
                    // Así garantizamos que bandit existe y es ejecutable por jenkins.
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
                    // Recordar: La app ya tiene host='0.0.0.0' gracias a tu corrección anterior
                    sh "docker run -d --name ${CONTAINER_NAME} --network ${NETWORK_NAME} ${IMAGE_NAME}"
                    sleep 10
                }
            }
        }

        stage('Escaneo OWASP ZAP') {
            steps {
                script {
                    // SOLUCIÓN ZAP: Truco de permisos.
                    // 1. Creamos el archivo vacío primero.
                    sh "touch reporte_zap.html"
                    // 2. Le damos permisos de escritura a "todo el mundo" (666).
                    // Esto permite que el usuario dentro del contenedor ZAP pueda escribir en él.
                    sh "chmod 666 reporte_zap.html"
                    
                    echo 'Iniciando ataque con OWASP ZAP...'
                    sh """
                    docker run --rm --network ${NETWORK_NAME} \
                    -v \$(pwd):/zap/wrk/:rw \
                    ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
                    -t http://${CONTAINER_NAME}:5000 \
                    -r reporte_zap.html \
                    -I || true
                    """
                    // El flag -I le dice a ZAP que no falle el build por warnings, pero || true asegura el paso.
                }
            }
        }
    }

    post {
        always {
            // Ahora sí deberían existir los archivos
            archiveArtifacts artifacts: 'reporte_bandit.json, reporte_zap.html', allowEmptyArchive: true
            
            script {
                sh "docker rm -f ${CONTAINER_NAME} || true"
                sh "docker network rm ${NETWORK_NAME} || true"
                // Opcional: borrar el entorno virtual para ahorrar espacio
                sh "rm -rf venv"
            }
        }
    }
}