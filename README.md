# TFG_CHATBOT
Repositório do Trabalho Final de Graduação.

Instruções para configuração e utilização do Chatbot;
Para execução do projeto utilizei o VSCode;
Comando para executar main.dart -> flutter run -d chrome --web-port=8080

# Configurando Flutter
- Baixar Flutter -> https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip
- Criar uma pasta chamada src no disco local e extrair o zip do flutter que foi baixado anteriormente.
procurar por Editar variáveis de ambiente do sistema > Avançado > Variáveis de Ambiente > Editar a variável PATH > NOVO > adicionar o caminho para pasta bin, exemplo: C:\src\flutter\bin > OK em tudo.
- Abrir PowerShell > cole o comando: flutter doctor > Aguarde até aparecer algo relacionado ao Flutter no PowerShell.

# Clonar esse repositório
https://github.com/PauloMM23/TFG_CHATBOT.git

# Configurar Google Cloud Console
https://console.cloud.google.com/welcome
- Criar Novo Projeto;
- Escolha um nome para o projeto, não precisa de organização;
- IAM e administrador > Contas de serviço: console.cloud.google.com/iam-admin/serviceaccounts > Criar conta de serviço (Colocar nome, o ID da conta já é criado a partir do nome escolhido) > Criar e continuar;
- Adicionar esses papéis: Administrador da conta de serviço, Administrador da Dialogflow API, Agente de serviço do Dialogflow, Cliente da Dialogflow API, Editor e Proprietário > concluir;

- Ativar APIs necessárias: console.cloud.google.com/apis/library > Dialogflow API e Google Calendar API;

- Criar Tela de Permissão OAuth: console.cloud.google.com/apis/credentials/consent > User Type = Externo > Criar;
- Preencher -> Nome do APP > Email de suporte so usuário > Dados de contato do desenvolvedor;
- Escopos é só Salvar e continuar;
- Usuários de teste é só Salvar e continuar;
- Voltar para o painel;

- Em Credenciais: console.cloud.google.com/apis/credentials > Criar credenciais > ID do cliente OAuth;
- Tipo do aplicativo > aplicativo web > Nome;
- Origens JavaScript autorizadas > Adicionar URl: http://localhost:8080 e http://localhost;
- URIs de redirecionamento autorizados > Adicionar URl: https://developers.google.com/oauthplayground e http://localhost:8080 > Criar;
- Guarde o ID do cliente e Chave secreta do cliente. Exemplo: ID cliente / Chave secreta do cliente

- Conta de serviço > Ações > Gerenciar Chaves > Adicionar Chave > Criar nova chave > JSON (Guarde esse arquivo);

# Configurar Dialogflow
https://dialogflow.cloud.google.com
- Crie um Agente, Nome, Português (Brazilian), Time Zone -3:00, Google project é o você criou no Google Cloud Console e clique em create;
- Espere um pouco para carregar o agente, vá na engrenagem do lado do nome do seu agente no canto superior esquerdo > Export and Import > Import from zip (utilize o zip que disponibilizei junto ao código do chatbot| nome do arquivo: Small-Talk.zip)

# Configurar Google Developers Playground
https://developers.google.com/oauthplayground/
- Clique na engrenagem no canto superior direito > Marque a opção Use your own OAuth credentials > Coloque o ID do cliente e a chave secreta do cliente que foram gerados no Google Cloud Console > Close;
- Step 1: Procure por Dialogflow API v3 e marque todas as opções dele (Aperte F3 para procurar mais rápido), mesma coisa para Google Calendar API v3 e Google OAuth2 API v2 > Clique em Authorize APIs;
- Step 2: Clique em Exchange authorization code for tokens e marque a opção Auto-refresh the token before it expires;
- Fim.

# Atualizando as credenciais no código do chatbot
- assets -> Colocar seu arquivo json na pasta assets, substituindo o já existente;
- main.dart -> clientId: "Seu clientID aqui";
            -> final jsonString = await rootBundle.loadString('assets/seuArquivoJsonAqui.json');
            -> Uri.parse('https://dialogflow.googleapis.com/v2/projects/ID_DO_SEU_PROJETO_GOOGLECONSOLE_AQUI/agent/sessions/$sessionId:detectIntent');
- pubspec.yaml -> assets:
                    - assets/seuArquivoJsonAqui.json



# FLUTTER

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
>>>>>>> 0379f84 (Initial commit)
