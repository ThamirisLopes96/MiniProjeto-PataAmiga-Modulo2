# Mini Projeto Avaliativo - Módulo 2 

# ANÁLISE DE DADOS PROJETO PATA AMIGA


## Identificação
* **Aluna:** Thamiris Lopes
* **Turma:** Análise de Dados T2
* **Base de dados:** Dados Rede Pata Amiga

## Sobre o projeto
Este projeto foi desenvolvido para analisar os dados da rede de pet shops Pata Amiga utilizando MySQL e um modelo dimensional.
A base possui 4.044 pedidos, realizados entre setembro de 2023 e março de 2024, além de informações sobre lojas, categorias de produtos e praças de atendimento.
A ideia principal foi pegar os dados que estavam separados e com alguns problemas de padronização e organizá-los para conseguir responder às cinco perguntas propostas no projeto.


## 📁 Estrutura do Projeto

O projeto contém os seguintes arquivos:

# Arquivos fornecidos
`00-conferencia.sql` = Validação dos scripts
`01-carga-staging.sql` = Cria o banco e carrega os dados das tabelas de origem como vieram dos sistemas
`02-dimensoes-prontas.sql`= Dimensões Prontas e Tabelas do modelo
`06-Dados brutos` = Dados brutos da base do cliente

# Arquivos de entreda
`03-dimensoes.sql` = Dimensões preenchidas para analise
`04-fato.sql` = Acontecimentos para responder questões analitcas
`05-perguntas.sql` = Respostas das perguntas de negócio
`README.md` = Arquivo explicativo e de apresentação do proojeto
`diagrama.png`= Diagrama do modelo estrela das tabelas

---
## Pré-requisitos

Antes de começar, certifique-se de ter o MYSQL para execução do projeto

## Como Executar o Projeto

1. Abra os arquivos de scripts na ordem em que estão enumerados, a partir do '01'
2. Copie todo o conteúdo
3. Abra uma instância do MySql e conecte
4. Abra uma aba de Query
5. Cole todo o coneúdo copiado
6. Clique em executar tudo

Primeiro foram conferidos os dados recebidos, depois o staging foi carregado. Em seguida foram construídas as dimensões e a tabela ponte, depois a tabela fato e, por último, as consultas para responder às perguntas.


## Tratamento dos dados
Antes de começar a criar as dimensões, foi necessário analisar como os dados estavam chegando.
As tabelas de staging não foram alteradas. O tratamento foi feito durante a inserção dos dados nas tabelas dimensionais e na fato.

** Datas
    Um dos pontos que exigiu mais atenção foram as datas.
    As datas de pedido e integração com o ERP estavam no formato americano, por exemplo:
    09/01/2023 10:27 AM
    Por isso foi necessário utilizar:
    STR_TO_DATE(campo, '%m/%d/%Y %h:%i %p')

    Os marcos da entrega estavam em outro formato, YYYY-MM-DD, e foram tratados separadamente.
    
** Valores
    Os valores também não estavam todos no mesmo formato.
    Foram encontrados casos como:
    R$ 1.850,00
    1850.00
    1.200
    -
    Os valores vazios ou representados por - foram mantidos como NULL. Isso é importante porque um valor desconhecido não significa que o valor seja zero.

** Categorias
    Foram encontradas 18 grafias diferentes de categorias.
    Foi criada uma regra para transformar essas grafias em categorias padronizadas.
    Um cuidado importante foi com a categoria Ração Medicamentosa. Como ela possui RA no nome, a regra de MED precisava ser verificada antes da regra de RA. Caso contrário, ela seria classificada como Racao.
** Lojas
    Também havia muitas formas diferentes de escrever o nome das lojas.
    Foi feita a padronização antes de realizar o relacionamento com a dim_loja.
    Além de remover /SC e espaços extras, foram corrigidos três nomes específicos:
    •	Blumenal → Blumenau;
    •	Floripa → Florianopolis;
    •	Jgua → Jaragua.
    Haviam 1.575 pedidos sem código da loja, mas somente 3 pedidos ficaram realmente sem identificação, pois não tinham nome de loja para fazer o relacionamento.
    Esses registros foram direcionados para a chave -1.

** Canal e desconto
    Os valores de desconto foram padronizados para:
    •	Sim;
    •	Nao;
    •	Nao Informado.
    Os canais foram transformados em:
    •	App;
    •	Site;
    •	Loja Fisica;
    •	Telefone;
    •	WhatsApp;
    •	Nao Informado.
    No caso do canal, WHATS foi colocado antes de APP, porque a palavra WhatsApp contém “APP”.

________________________________________
Diagnóstico da origem

    Antes do tratamento, os principais problemas encontrados foram:
    Informação	Quantidade
    Pedidos	4.044
    Lojas	32
    Relações loja × praça	48
    Grafias de loja	50
    Grafias de categoria	18
    Pedidos sem código da loja	1.575
    Pedidos sem nome da loja	3
    Separação em branco	1.077
    Nota em branco	1.338
    Despacho em branco	1.665
    Entrega em branco	1.953

    Esses problemas foram considerados no processo de carga.

## Diagrama da Modelagem

Este diagrama apresenta o modelo dimensional do projeto. 
No centro temos a fato_pedido, com uma linha para cada pedido. Ela se relaciona às dimensões de loja, categoria e tempo, sendo que a dim_tempo é utilizada tanto para a data do pedido quanto para a data da entrega. 
Já a dimensão praça é relacionada por meio da bridge_loja_praca, permitindo representar lojas que atendem mais de uma praça e realizar o rateio do faturamento.

![alt text](<Diagrama Mini Projeto Pata Amiga.png>)

## RESPOSTAS DAS ANÁLISES


1. Onde está o gargalo da entrega?

O resultado por porte de loja foi:

| Porte | Integração → Separação | Separação → Nota | Nota → Despacho | Despacho → Entrega | Total |
|---|---:|---:|---:|---:|---:|
| Pequena | 3,02 | 0,69 | 8,53 | 2,86 | 15,16 |
| Média | 1,98 | 0,62 | 3,34 | 2,03 | 7,95 |
| Grande | 1,96 | 0,64 | 3,32 | 2,01 | 7,93 |

O maior tempo aparece na etapa Nota → Despacho.
Ocorre nos três portes, porém com uma atenção maior nas de porte menor.
Enquanto as lojas médias e grandes ficam próximas de 8 dias no processo total, as pequenas chegam a 15,16 dias.
Necessário investigar possível problema operacional nessa etapa nas lojas menores. 
________________________________________
2. Qual categoria representa a maior parte do faturamento?

A distribuição encontrada foi:

| Categoria | Faturamento | Participação |
|---|---:|---:|
| Ração | R$ 1.076.202,55 | 60,01% |
| Medicamento | R$ 305.904,03 | 17,06% |
| Petisco | R$ 128.590,16 | 7,17% |
| Serviço | R$ 94.001,37 | 5,24% |
| Higiene | R$ 92.314,45 | 5,15% |
| Acessório | R$ 64.661,39 | 3,61% |
| Brinquedo | R$ 31.634,56 | 1,76% |

A Racao representa aproximadamente 60% do faturamento.
Também foi verificado o resultado por porte e a categoria continua sendo a de maior faturamento nas lojas pequenas, médias e grandes.
Isso mostra que a rede possui uma concentração considerável de receita nessa categoria. 
Com isso, é possível validar a importância da Racao para o negócio, também seria interessante acompanhar as outras categorias para evitar uma dependência muito grande de apenas uma delas.
________________________________________
3. O desconto apresenta o mesmo comportamento em todos os canais?

Os tickets médios encontrados foram:

| Canal | Sem desconto | Com desconto |
|---|---:|---:|
| App | R$ 167,63 | R$ 488,04 |
| Loja Física | R$ 197,55 | R$ 494,04 |
| Site | R$ 189,68 | R$ 501,92 |
| Telefone | R$ 195,23 | R$ 514,02 |
| WhatsApp | R$ 179,26 | R$ 514,33 |

Os pedidos com desconto tiveram ticket médio maior em todos os canais analisados.
O App também teve uma participação importante no faturamento, representando 27,70% do total, com R$ 496.822,22.
Porém, não considero correto afirmar somente com esses dados que o desconto fez o cliente gastar mais. Pode haver outros fatores envolvidos, como tipo de produto, quantidade de itens ou perfil do pedido.
Para verificar realmente o efeito do desconto seria necessário fazer uma análise mais específica.
________________________________________
4. Qual praça concentra o faturamento?

Para essa análise foi utilizado o fator de público da tabela bridge_loja_praca.

O maior resultado foi encontrado no Vale do Itajai:

- **148.000** domicílios com pet;
- **R$ 633.746,09** de faturamento rateado;
- **R$ 4,28** de faturamento por domicílio.

A comparação com as outras praças mostrou:

| Praça | Faturamento rateado |
|---|---:|
| Vale do Itajaí | R$ 633.746,09 |
| Grande Florianópolis | R$ 283.546,75 |
| Norte Industrial | R$ 175.431,90 |
| Litoral Sul | R$ 137.051,20 |
| Litoral Norte | R$ 128.872,75 |

O uso do fator é importante porque uma loja pode atender mais de uma praça. Sem esse cálculo, o faturamento de uma loja poderia ser contado mais de uma vez.

Conferência:

O faturamento rateado das praças foi: R$ 1.792.322,21
Somando os pedidos sem loja: R$ 986,30
Temos: R$ 1.793.308,51

Esse valor é igual ao faturamento total da fato.
________________________________________
5. Expansão da rede

a) Itens vendidos por mil habitantes

As lojas com maiores índices encontrados foram:

| Loja | Itens por 1.000 habitantes | Tempo médio de entrega |
|---|---:|---:|
| Rio dos Cedros | 41,87 | 14,24 dias |
| Presidente Getúlio | 34,84 | 14,16 dias |
| Ibirama | 32,07 | 15,39 dias |
| Itapoá | 25,94 | 15,39 dias |
| Santo Amaro da Imperatriz | 23,71 | 15,88 dias |

Rio dos Cedros apresentou o maior indicador.
Um ponto que achei interessante foi que as lojas com maior venda relativa também possuem tempos de entrega relativamente altos. Isso pode indicar que existe demanda, mas a operação também precisa ser analisada.

b) Faixa das franquias

Considerando a faixa atual cadastrada:

| Faixa | Faturamento |
|---|---:|
| Ouro | R$ 1.011.264,38 |
| Diamante | R$ 382.209,74 |
| Prata | R$ 314.812,03 |
| Bronze | R$ 84.036,06 |

As lojas Ouro apresentam o maior faturamento.

Mas existe uma limitação importante: essa é a classificação atual. O histórico da faixa não foi preservado.
Portanto, não dá para saber se uma loja que hoje é Ouro também era Ouro quando determinado pedido aconteceu.

c) Dados incompletos

Na fato ficaram:

- **3 pedidos** sem loja;
- **1.953 pedidos** sem entrega;
- **257 pedidos** sem quantidade de itens;
- **121 pedidos** sem valor.

O número de pedidos sem entrega é especialmente relevante, porque representa aproximadamente 48,29% da base.
________________________________________
Conclusão

Depois de realizar o tratamento e as análises, os dados mostram três pontos que considero mais importantes:

1.	o principal gargalo está entre a emissão da nota e o despacho;
2.	Racao representa a maior parte do faturamento da rede;
3.	algumas lojas pequenas apresentam alta quantidade de itens vendidos por habitante, mas também possuem tempos de entrega elevados.
Para uma possível expansão, eu começaria investigando Rio dos Cedros, seguida pelas outras localidades com indicadores altos.
Isso não significa que os dados sejam suficientes para decidir sozinhos onde abrir uma loja. Antes da decisão seria importante analisar concorrência, custos, demanda, logística e potencial de crescimento.


________________________________________
Validações
No final da construção foram conferidos os principais resultados:
•	4.044 pedidos na fato;
•	0 FKs nulas ou órfãs;
•	3 pedidos na loja -1;
•	1.953 pedidos sem entrega;
•	período de 01/09/2023 a 31/03/2024;
•	faturamento total de R$ 1.793.308,51;
•	faturamento arredondado de R$ 1.793.309;
•	rateio das praças reconciliado com o faturamento total.


                    