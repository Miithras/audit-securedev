pipeline {
    agent any

    environment {
        // Nombres para limpieza fácil
        IMAGE_NAME = "vulnerable-flask-app"
        CONTAINER_NAME = "vulnerable-app-instance"
        NETWORK_NAME = "audit-net"
    }

    stages {
        // ETAPA 1: Preparación
        stage('Limpieza Inicial') {
            steps {
                script {
                    // Limpiamos contenedores o redes previas para evitar conflictos
                    sh "docker rm -f ${CONTAINER_NAME} || true"
                    sh "docker network rm ${NETWORK_NAME} || true"
                }
            }
        }

        // ETAPA 2: Análisis Estático de Código (SAST)
        // Esto lee tus scripts .py directamente
        stage('Análisis Estático (Bandit)') {
            steps {
                script {
                    echo 'Ejecutando Bandit para analizar el código Python...'
                    // Usamos un contenedor temporal de Python para correr Bandit sobre tus archivos
                    sh """
                    docker run --rm -v \$(pwd):/code python:3.9-slim /bin/bash -c "
                        pip install bandit && 
                        bandit -r /code -f json -o /code/reporte_bandit.json || true
                    "
                    """
                    // El "|| true" permite que el pipeline continúe aunque encuentre fallos
                }
            }
        }

        // ETAPA 3: Construcción y Despliegue
        // Necesario para que OWASP ZAP pueda atacar la app
        stage('Construir y Desplegar') {
            steps {
                script {
                    echo 'Construyendo imagen Docker...'
                    sh "docker build -t ${IMAGE_NAME} ."
                    
                    echo 'Creando red de auditoría...'
                    sh "docker network create ${NETWORK_NAME}"
                    
                    echo 'Desplegando aplicación...'
                    sh "docker run -d --name ${CONTAINER_NAME} --network ${NETWORK_NAME} ${IMAGE_NAME}"
                    
                    // Esperamos a que la base de datos y Flask inicien
                    sleep 10
                }
            }
        }

        // ETAPA 4: Análisis Dinámico (DAST)
        // Esto ataca la app corriendo con OWASP ZAP
        stage('Escaneo OWASP ZAP') {
            steps {
                script {
                    echo 'Iniciando ataque con OWASP ZAP...'
                    // Ejecutamos ZAP Baseline Scan
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
            // Recolectar evidencias para el informe (Artefactos)
            archiveArtifacts artifacts: 'reporte_bandit.json, reporte_zap.html', allowEmptyArchive: true
            
            // Limpieza final de Docker
            script {
                sh "docker rm -f ${CONTAINER_NAME} || true"
                sh "docker network rm ${NETWORK_NAME} || true"
            }
        }
    }
}