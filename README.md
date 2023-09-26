# AWS-RDS-ECS_PRIVATE
## Antes de executar o terraform, lembrar que você deve criar o ECR manualmente, por causa da demora no push do docker image para a aws, ai por questões de custo, resolvi deixar separado. Então quando criar o ECR e fizer o push da imagem, pegar o URI e alterar a string de nome IMAGEM, no arquivo main.tf, mesma coisa para imagem-prometheus e imagem-alert-manager.

## Caso queira pegar a imagem docker do projeto, pegar nos repositorios: 
## harrisonlima/kube-news:v1
## harrisonlima/prometheus2.47-alterado
## harrisonlima/alertmanager0.26-alterado


## Before execute the terraform, remember that you must create ECR manually, because of the waiting to push the docker image to aws, so for cost reasons, i decided to leave it separate. When you have created you ECR and pushed your docker image, take the URI and change the string of name IMAGEM in the main.tf file, same thing for imagem-prometheus and imagem-alert-manager.

## In case you want to take the docker image of the project, take it in the repositories:
## harrisonlima/kube-news:v1
## harrisonlima/prometheus2.47-alterado
## harrisonlima/alertmanager0.26-alterado