# Pousada Acalanto App

Aplicativo móvel de gestão de reservas desenvolvido em **Flutter** para a **Pousada Acalanto**.

Este projeto faz parte do **Projeto Integrador V-A (Extensão)** do curso de Análise e
Desenvolvimento de Sistemas da **PUC Goiás**.

---

## Sobre o Projeto

O objetivo deste trabalho extensionista foi desenvolver uma solução tecnológica para substituir
controles manuais e otimizar a gestão de hospedagem de um parceiro da comunidade local.

A aplicação permite o controle total do ciclo de vida de uma reserva, desde o cadastro do hóspede
até o faturamento financeiro, garantindo integridade de dados e prevenindo erros comuns.

---

## Vídeo de Demonstração

Abaixo está um vídeo demonstrando as principais telas da aplicação em funcionamento e outras funcionalidades:

[![Assista ao Vídeo Demonstrativo](https://img.youtube.com/vi/OESX0HvtBTU/0.jpg)](https://www.youtube.com/watch?v=OESX0HvtBTU)
---

## Metodologia Aplicada: Extreme Programming (XP)

O desenvolvimento seguiu rigorosamente os valores da metodologia ágil **XP (Extreme Programming)**,
focando em ciclos curtos e qualidade de código:

* **Simplicidade:** O design foi mantido limpo, implementando apenas o que a pousada realmente
  precisava para operar, sem funcionalidades excessivas.
* **Feedback Constante:** O aplicativo foi construído em iterações. A cada funcionalidade entregue (
  ex: CRUD básico), o parceiro validava e sugeria melhorias (ex: necessidade do filtro de
  faturamento).
* **Refatoração:** O código sofreu melhorias contínuas, como a otimização da lógica de verificação
  de datas para garantir performance.

---

## Relato das Interações com o Parceiro

A parceria foi estabelecida com a gestão da **Pousada Acalanto**, identificando a necessidade de
digitalizar o controle de hóspedes que, anteriormente, dependia de processos manuais suscetíveis a
falhas.

Durante o ciclo de desenvolvimento (Novembro/2025), ocorreram interações semanais:

1. **Diagnóstico:** Identificamos que o maior problema era o controle de datas (saber qual quarto
   estava livre em qual dia) e o fechamento de caixa mensal.
2. **Entregas Incrementais:** Apresentei primeiramente a lista de reservas. O parceiro solicitou
   uma forma visual de saber quem já havia pago.
3. **Ajustes Finais:** Com base no feedback, implementei a trava de segurança que impede
   selecionar um quarto ocupado e o relatório de faturamento mensal editável.

Essas interações validaram a importância da **Comunicação** e do **Feedback**, pilares essenciais do
XP.

---

## Percepções sobre o Impacto

A implantação do aplicativo trouxe impactos imediatos na organização da Pousada Acalanto:

* **Eliminação de Overbooking:** A lógica de verificação de disponibilidade (`_checkAvailability`)
  eliminou o risco humano de reservar o mesmo quarto para duas pessoas na mesma data.
* **Agilidade no Atendimento:** Com a busca rápida e os filtros por status (*Agendado, Hospedado,
  Finalizado*), o tempo de check-in foi reduzido.
* **Visibilidade Financeira:** O gestor agora consegue visualizar o faturamento do mês em segundos,
  algo que antes exigia somar fichas manuais.
* **Segurança de Dados:** A persistência em banco de dados local (SQLite) garantiu que as
  informações históricas fossem preservadas e organizadas.

---

## Funcionalidades Técnicas

* **CRUD Completo:** Criação, Leitura, Atualização e Exclusão de reservas.
* **Gestão de Status:** Fluxo visual de *Pendente* → *Check-in* → *Check-out*.
* **Trava de Disponibilidade:** Algoritmo que compara datas de entrada/saída e bloqueia quartos
  ocupados no formulário.
* **Controle Financeiro:**
    * Painel de Faturamento Mensal dinâmico.
    * Validação de pagamento obrigatório antes do Check-out.
* **UX/UI:** Máscaras automáticas (CPF/Telefone), feedbacks visuais (Snackbars) e validação de
  formulário.
* **Persistência:** Uso de **SQLite** para armazenamento seguro e offline.

---

## Tecnologias Utilizadas

* **Linguagem:** Dart
* **Framework:** Flutter (Mobile)
* **Banco de Dados:** SQLite (pacote `sqflite`)
* **IDE:** Android Studio
* **Pacotes Principais:**
    * `intl`: Formatação de datas e moedas.
    * `mask_text_input_formatter`: Máscaras de input.
    * `path`: Gerenciamento de diretórios do sistema.

---

## Como Rodar o Projeto

### Pré-requisitos

* Flutter SDK instalado.
* Android Studio configurado com Emulador ou Dispositivo Físico via USB.

### Passo a Passo

1. **Clone o repositório** (ou baixe os arquivos):
   ```bash
   git clone https://github.com/Felipe-Sant-ana/Projeto-Pousada-Acalanto.git
   ```

2. **Instale as dependências:**
   No terminal, dentro da pasta do projeto, execute:
   ```bash
   flutter pub get
   ```

3. **Execute o aplicativo:**
   ```bash
   flutter run
   ```
   *Nota: Para melhor performance (sem lentidão de debug), utilize:*
   ```bash
   flutter run --release
   ```

---

## Estrutura do Código

O projeto segue uma arquitetura modular para facilitar a manutenção:

* `lib/main.dart`: Tela principal (Home), gerenciamento de estado e navegação.
* `lib/database_helper.dart`: Singleton responsável pela conexão, criação da tabela e operações SQL.
* `lib/reservation_model.dart`: Modelo de dados (Entidade Reserva com métodos de serialização).
* `lib/reservation_form_screen.dart`: Tela de formulário contendo todas as regras de negócio
  complexas (conflito de datas, validações).
* `lib/splash_screen.dart`: Tela de abertura com a identidade visual.

---

## Autoria

**Aluno:** Felipe Oliveira Sant'Ana  
**Curso:** Análise e Desenvolvimento de Sistemas  
**Instituição:** Pontifícia Universidade Católica de Goiás (PUC Goiás)  
**Disciplina:** Projeto Integrador V - A  
**Professor Orientador:** Thalles Bruno Goncalves Nery dos Santos  
**Data:** 25 de Novembro de 2025
