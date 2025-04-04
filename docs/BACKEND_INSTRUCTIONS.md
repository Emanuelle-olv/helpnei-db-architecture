
# Instruções para o Time de Backend

Este documento tem como objetivo orientar o time de desenvolvimento backend sobre os comportamentos já automatizados no banco de dados (via triggers e eventos), além de destacar os pontos onde é necessária atenção do backend.

---

## 📌 Visão Geral

O banco de dados deste projeto possui automações importantes implementadas diretamente via **triggers** e **event scheduler (MySQL)**. Essas automações foram criadas para:

- Garantir a integridade dos dados.
- Aplicar regras de negócio automaticamente.
- Evitar falhas manuais no código backend.
- Reduzir a complexidade e responsabilidade do backend em certos pontos.

---

## ⚙️ TRIGGERS AUTOMÁTICAS

### 1. `trg_set_expiration_date`
- **Quando acontece**: Antes de inserir um novo registro em `sponsorship_selection`.
- **O que faz**: Define automaticamente a coluna `expiration_date` com a data atual + 3 dias.
- **Backend**: Não precisa preencher essa coluna, será feita automaticamente pelo banco.

---

### 2. `trg_decrement_slot_on_insert`
- **Quando acontece**: Após inserir uma nova seleção de patrocínio (`sponsorship_selection`).
- **O que faz**: Reduz automaticamente em -1 o número de vagas disponíveis na tabela `sponsorship_slot`.
- **Backend**: Não precisa controlar a contagem de vagas. Basta inserir o `slot_id` corretamente.

---

### 3. `trg_prevent_duplicate_cpf`
- **Quando acontece**: Antes de inserir um novo candidato (`capture_candidate`).
- **O que faz**: Bloqueia o cadastro se o CPF já foi cadastrado nos últimos 30 dias.
- **Backend**: Precisa **capturar o erro** de SQL do tipo:
  ```
  ERROR 1644 (45000): Cadastro recusado: já existe um candidato com este CPF nos últimos 30 dias.
  ```
  **exemplo de solução**

```sql
CREATE TRIGGER trg_prevent_duplicate_cpf
BEFORE INSERT ON capture_candidate
FOR EACH ROW
BEGIN
    DECLARE recent_count INT;
    SELECT COUNT(*) INTO recent_count
    FROM capture_candidate
    WHERE cpf = NEW.cpf AND created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY);

    IF recent_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cadastro recusado: já existe um candidato com este CPF nos últimos 30 dias.';
    END IF;
END;
```

Essa trigger impede que o mesmo CPF seja cadastrado mais de uma vez em um intervalo de 30 dias. No entanto, **o banco apenas lança um erro técnico**, e **o backend é responsável por capturar esse erro e apresentar uma mensagem clara e amigável ao usuário**.

#### ✅ O que o backend deve fazer:

1. Envolver o `create` do Prisma em um bloco `try/catch`.
2. Verificar se o erro retornado corresponde a um erro de trigger.
3. Traduzir esse erro para uma mensagem compreensível, como:

> "Já existe um cadastro com este CPF nos últimos 30 dias."

#### 💡 ✅ Função registerCandidate com tratamento de erro:

```ts
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * Registra um novo candidato para o programa de patrocínio.
 * Verifica erro lançado por trigger caso o CPF já tenha sido cadastrado nos últimos 30 dias.
 * 
 * @param data Objeto com os dados do candidato
 * @returns Objeto do candidato criado
 * @throws Erro amigável se CPF for duplicado, ou erro genérico se falhar
 */
export async function registerCandidate(data: {
  full_name: string;
  cpf: string;
  birth_date?: Date;
  gender?: string;
  street?: string;
  number?: string;
  complement?: string;
  state?: string;
  city?: string;
  phone?: string;
  family_income?: number;
  email?: string;
  education_level?: string;
  notification_method?: string;
}) {
  try {
    const candidate = await prisma.capture_candidate.create({
      data,
    });

    return candidate;

  } catch (error: any) {
    // Tratamento de erro gerado pela trigger do banco (duplicidade de CPF)
    if (
      error.code === 'P2003' || // erro de integridade
      error.message?.toLowerCase().includes('cpf') ||
      error.message?.toLowerCase().includes('cadastro recusado')
    ) {
      throw new Error('Já existe um cadastro com este CPF nos últimos 30 dias.');
    }

    // Outro erro desconhecido
    throw new Error('Erro interno ao cadastrar candidato.');
  }
}

```
#### 📌 Onde usar: 
Essa função pode ser chamada por rotas como:

```ts
app.post('/api/candidato', async (req, res) => {
  try {
    const candidato = await registerCandidate(req.body);
    res.status(201).json(candidato);
  } catch (err: any) {
    res.status(400).json({ message: err.message });
  }
});

```
Essa abordagem garante uma melhor experiência de usuário e evita mensagens técnicas confusas.

---

### 4. `trg_prevent_overlap_insert` e `trg_prevent_overlap_update`
- **Quando acontece**: Ao tentar criar (`trg_prevent_overlap_insert`) ou atualizar(`trg_prevent_overlap_update`) um novo patrocínio na tabela `owner_sponsor_plan`.
- **O que faz**: Impede que um mesmo `owner` receba dois patrocínios com intervalos de datas sobrepostos.
- **Backend**: Capturar erro retornado pelo banco com mensagem:
  ```
  ERROR 1644 (45000): Conflito: este owner já possui patrocínio ativo neste intervalo.
  ```

---

### 5. `trg_set_end_date`
- **Quando acontece**: Antes de inserir um novo patrocínio em `owner_sponsor_plan`.
- **O que faz**: Calcula automaticamente o `end_date` com base na coluna `start_date` somada ao `duration_months` do plano associado.
- **Backend**: Só precisa informar o `start_date`. O `end_date` será calculado internamente.

---

## ⏲️ EVENTO AGENDADO (EVENT SCHEDULER - Agendamento de Tarefas)

### `ev_auto_reject_expired`
- **Executa automaticamente a cada hora**.
- **O que faz**:
  1. Verifica todas as linhas da tabela `sponsorship_selection` com `status = 'pending'` e `expiration_date < NOW()`.
  2. Atualiza o status para `'rejected'`.
  3. Devolve a vaga ao slot correspondente, incrementando em +1 o `slot_quantity_available`.

- **Backend**: Não precisa fazer verificação de prazo de seleção. O banco cuida disso.
- **Importante**: O status `'approved'` só pode vir de uma **integração futura** com a API da Helpnei (fora do escopo atual).

---

## 🧾 VIEWS

As views foram criadas para facilitar consultas agregadas e serão consumidas apenas para leitura:

- `vw_active_sponsored_owners`: owners com patrocínio ativo atualmente.
- `vw_all_sponsored_owners`: todos os owners que já foram patrocinados.
- `vw_store_impact`: total de lojas criadas por cada owner no período do patrocínio.
- `vw_user_impact`: total de usuários convidados por owner no período do patrocínio.
- `vw_community_impact`: total de comunidades criadas por owner no período do patrocínio.
- `vw_total_impacted_users`: total de usuários impactados (diretos e das comunidades) — sem duplicidade.

**Backend**: Essas views podem ser usadas diretamente via SELECTs para exibir relatórios e dashboards, sem necessidade de cálculos adicionais.

---

## ✅ Checklist de Ações do Backend

| Ação                                                                 | Responsável     |
|----------------------------------------------------------------------|------------------|
| Tratar erro de CPF duplicado (trigger)                              | ✅ Backend       |
| Tratar erro de conflito de datas de patrocínio                      | ✅ Backend       |
| Garantir que a data de início de patrocínio venha corretamente      | ✅ Backend       |
| Usar as views para leitura agregada                                 | ✅ Backend       |
| Não atualizar diretamente `slot_quantity_available`                 | ❌ Banco cuida disso |
| Não atualizar diretamente `expiration_date`                         | ❌ Banco cuida disso |
| Consultar `status_selection` para saber se a vaga foi ativada       | ✅ Backend       |
| Capturar mensagens de erro do banco e traduzir para mensagens claras no frontend | ✅ Backend       |

---


## 🔧 Backend - O que precisa ser tratado

- **Não repetir lógicas já tratadas no banco:** Exemplo: cálculo de end_date ou controle de disponibilidade de vagas já é automático.
- **Mensagens de erro do banco:** Como as triggers usam `SIGNAL SQLSTATE`, o backend precisa capturar erros como CPF duplicado e exibir mensagens apropriadas para o usuário.


## 🧠 Observações

- O uso de triggers e eventos foi escolhido para **garantir integridade** e reduzir a complexidade do backend.
- Toda a modelagem foi feita seguindo **boas práticas**, com separação entre os módulos e documentação detalhada.

- **Integração via API Helpnei:** Quando a Helpnei venha a disponibilizar uma API que confirme a ativação do usuário na plataforma, o backend deverá atualizar o status para `'approved'` manualmente (via endpoint ou integração programada), assim como: 
  - Criar o novo registro na tabela `owner`.
  - Criar automaticamente a entrada na tabela `owner_sponsor_plan`, respeitando a lógica já automatizada da trigger `trg_set_end_date`.
 