# Integração do Prisma com o Banco de Dados Helpnei

Esta pasta contém o schema do Prisma e scripts de exemplo para consultar views SQL utilizando o Prisma.

## Estrutura

- `schema.prisma` – Convertido a partir do `init.sql` original  
- `queryViews.ts` – Exemplo de como buscar dados de views SQL via Prisma   
- `triggers_and_events.sql` – Deve ser executado diretamente, pois o Prisma **não** oferece suporte a triggers ou eventos  

## Como Usar

1. Certifique-se de que o banco de dados já está em execução e que as views foram criadas.  
2. Gere o cliente do Prisma:  
```bash
npx prisma generate      #uma maneira, abaixo explico outra maneira de executar
```
3. Execute as consultas de exemplo nas views: 

```bash
ts-node queryViews.ts
```


# 💾 Criando o Banco de Dados com Prisma

Este projeto utiliza o **Prisma ORM** para modelar e interagir com o banco de dados MySQL. Existem duas formas principais de aplicar o schema ao banco. Ambas têm suas vantagens, mas também limitações importantes que precisam ser complementadas com scripts SQL manuais.

---

## ✅ Opção 1: Usando `prisma migrate dev`

```bash
npx prisma migrate dev --name init
```

### O que essa opção faz:
- Cria todas as tabelas definidas no `schema.prisma`.
- Cria chaves primárias e estrangeiras.
- Cria índices simples.
- Registra o histórico das migrações na pasta `prisma/migrations`.

### Pontos positivos:
- Ideal para ambientes de desenvolvimento.
- Seguro, rastreável, automatizado.

### Limitações:
❌ **Não cria**:
- Views (`CREATE VIEW`)
- Triggers (`CREATE TRIGGER`)
- Eventos agendados (`EVENT SCHEDULER`)

### Ações manuais obrigatórias:
Após rodar o comando acima, **execute manualmente os scripts SQL**:

```bash
mysql -u root -p helpnei < sql/views.sql
mysql -u root -p helpnei < sql/triggers_and_events.sql
```

---

## 🧩 Opção 2: Usando `prisma generate` (sem aplicar no banco)

```bash
npx prisma generate
```

### O que essa opção faz:
- **Gera o Prisma Client** para uso no TypeScript.
- Permite consultar e manipular dados **somente se as tabelas já existirem** no banco.

### Quando usar:
- Quando o banco já foi criado **manualmente** com arquivos `.sql`.
- Quando você não deseja que o Prisma sobrescreva nada.

### Limitações:
- O Prisma **não cria nada no banco** com esse comando.
- Ainda assim, ele depende do schema correto no banco para funcionar.

---

## 📌 Conclusão

| Ação                          | `migrate dev` | `generate` |
|-------------------------------|---------------|------------|
| Cria tabelas                  | ✅            | ❌         |
| Gera Prisma Client            | ✅            | ✅         |
| Cria triggers, views, events  | ❌ (manual)   | ❌ (manual)|
| Melhor para...                | Desenvolvimento | Projetos existentes |

---