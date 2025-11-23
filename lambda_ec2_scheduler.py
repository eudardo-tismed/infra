import boto3
import json
import logging

# Configurar logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Função Lambda para iniciar ou parar instâncias EC2 baseado no evento recebido
    """
    
    # Inicializar cliente EC2
    ec2 = boto3.client('ec2')
    
    try:
        # Obter a ação do evento (start ou stop)
        action = event.get('action', 'unknown')
        
        # ID da instância EC2 (será passado via variável de ambiente ou evento)
        instance_id = event.get('instance_id')
        
        if not instance_id:
            logger.error("Instance ID não fornecido no evento")
            return {
                'statusCode': 400,
                'body': json.dumps('Instance ID é obrigatório')
            }
        
        if action == 'stop':
            # Parar a instância
            logger.info(f"Parando instância EC2: {instance_id}")
            response = ec2.stop_instances(InstanceIds=[instance_id])
            message = f"Instância {instance_id} sendo parada"
            
        elif action == 'start':
            # Iniciar a instância
            logger.info(f"Iniciando instância EC2: {instance_id}")
            response = ec2.start_instances(InstanceIds=[instance_id])
            message = f"Instância {instance_id} sendo iniciada"
            
        else:
            logger.error(f"Ação inválida: {action}")
            return {
                'statusCode': 400,
                'body': json.dumps(f'Ação inválida: {action}. Use "start" ou "stop"')
            }
        
        logger.info(f"Operação {action} executada com sucesso para {instance_id}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': message,
                'response': response
            })
        }
        
    except Exception as e:
        logger.error(f"Erro ao executar ação {action}: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Erro interno: {str(e)}')
        }