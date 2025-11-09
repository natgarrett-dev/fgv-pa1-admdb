-- Database: pa1-admbd-v1
-- DROP DATABASE IF EXISTS "pa1-admbd-v1";
CREATE DATABASE "pa1-admbd-v1"
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'English_United States.1252'
    LC_CTYPE = 'English_United States.1252'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

-- pratica_avaliada1.sql
-- Script completo para a "Prática Avaliada 1 – Chaves Imóveis"

-- 0) Preparação: usar transação de segurança para criar tudo
BEGIN; -- início da transação principal

-- 2) Criação de tabelas  - Chaves Imóveis
-- proprietarios: donos dos imóveis
CREATE TABLE IF NOT EXISTS proprietarios (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(14) UNIQUE,
    telefone VARCHAR(20)
);

-- corretores: agentes
CREATE TABLE IF NOT EXISTS corretores (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    creci VARCHAR(20) UNIQUE
);

-- clientes: quem aluga/compra
CREATE TABLE IF NOT EXISTS clientes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(14) UNIQUE
);

-- imoveis: imóveis disponíveis ou não
CREATE TABLE IF NOT EXISTS imoveis (
    id SERIAL PRIMARY KEY,
    endereco VARCHAR(200) NOT NULL,
    bairro VARCHAR(100),
    valor_aluguel NUMERIC(12,2),
    disponivel_aluguel BOOLEAN DEFAULT TRUE,
    proprietario_id INTEGER REFERENCES proprietarios(id) ON DELETE SET NULL
);

-- vendas: registro de vendas de imóveis
CREATE TABLE IF NOT EXISTS vendas (
    id SERIAL PRIMARY KEY,
    imovel_id INTEGER REFERENCES imoveis(id) ON DELETE SET NULL,
    corretor_id INTEGER REFERENCES corretores(id) ON DELETE SET NULL,
    cliente_id INTEGER REFERENCES clientes(id) ON DELETE SET NULL,
    valor NUMERIC(12,2),
    data_venda DATE
);

-- alugueis: registros de contratos de aluguel
CREATE TABLE IF NOT EXISTS alugueis (
    id SERIAL PRIMARY KEY,
    imovel_id INTEGER REFERENCES imoveis(id) ON DELETE CASCADE,
    cliente_id INTEGER REFERENCES clientes(id) ON DELETE SET NULL,
    data_inicio DATE,
    data_fim DATE,
    valor NUMERIC(12,2),
    data_contrato DATE
);

-- 3) Inserindo dados de exemplo
-- proprietarios
INSERT INTO proprietarios (nome, cpf, telefone) VALUES
('Mariana Silva', '111.111.111-11', '11-99999-0001'),
('João Pereira',   '222.222.222-22', '11-99999-0002'),
('Ana Costa',      '333.333.333-33', '11-99999-0003')
ON CONFLICT DO NOTHING;

-- corretores
INSERT INTO corretores (nome, creci) VALUES
('Carlos Souza', 'CRECI-1001'),
('Fernanda Lima','CRECI-1002'),
('Rafael Alves', 'CRECI-1003')
ON CONFLICT DO NOTHING;

-- clientes
INSERT INTO clientes (nome, cpf) VALUES
('Pedro Santos','444.444.444-44'),
('Mariana Silva','111.111.111-11'),
('Lucas Rocha','555.555.555-55'),
('Carla Dias','666.666.666-66')
ON CONFLICT DO NOTHING;

-- imoveis 
INSERT INTO imoveis (endereco, bairro, valor_aluguel, disponivel_aluguel, proprietario_id) VALUES
('Rua A, 100','Centro', 1500.00, TRUE, 1),
('Av B, 200','Jardim', 2500.00, TRUE, 2),
('Rua C, 300','Centro', 1800.00, FALSE, 1),
('Rua D, 400','Vila Nova', 1200.00, TRUE, 3),
('Av E, 500','Jardim', 3000.00, FALSE, 2)
ON CONFLICT DO NOTHING;

-- vendas exemplo (atrlando alguns imóveis a corretores)
INSERT INTO vendas (imovel_id, corretor_id, cliente_id, valor, data_venda) VALUES
(3, 1, 2, 250000.00, '2021-06-15'),
(5, 2, 3, 320000.00, '2022-09-10'),
(3, 1, 4, 260000.00, '2023-03-20')
ON CONFLICT DO NOTHING;

-- alugueis
INSERT INTO alugueis (imovel_id, cliente_id, data_inicio, data_fim, valor, data_contrato) VALUES
(1, 1, '2019-01-01', '2019-12-31', 1400.00, '2019-01-01'),
(1, 1, '2021-01-01', '2021-12-31', 1500.00, '2021-01-01'),
(2, 4, '2020-06-01', '2021-05-31', 2400.00, '2020-06-01'),
(4, 3, '2022-02-01', '2022-12-31', 1150.00, '2022-02-01'),
(2, 1, '2023-01-01', '2023-12-31', 2600.00, '2023-01-01')
ON CONFLICT DO NOTHING;

COMMIT; -- finaliza a transação principal de criação e inserts

-- Atividade 1: Criação de usuários e roles (20 pontos)
-- a) Crie um usuário chamado "corretor" com senha.

ROLLBACK; -- "limpar" a transação abortada

BEGIN;
CREATE USER corretor WITH PASSWORD 'SenhaForte123';
-- b) Crie uma role chamada "gerente" sem login.
CREATE ROLE gerente NOLOGIN;
-- c) Conceda à role gerente permissão total (DDL e DML) sobre todas as tabelas do banco.
--    Para permitir DDL (criar/alterar tabelas) no schema public, damos CREATE no schema.
GRANT CREATE ON SCHEMA public TO gerente;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO gerente;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO gerente;
-- d) Adicione o usuário corretor à role gerente (fazendo corretor membro de gerente).
GRANT gerente TO corretor;
COMMIT;

-- Atividade 2: Consultas SQL (40 pontos)
--    (a) Liste todos os imóveis disponíveis para aluguel, mostrando endereço, valor e nome do proprietário.
-- CONSULTA A:
SELECT i.endereco, i.bairro, i.valor_aluguel, p.nome AS proprietario
FROM imoveis i
LEFT JOIN proprietarios p ON i.proprietario_id = p.id
WHERE i.disponivel_aluguel = TRUE
ORDER BY i.endereco;

-- (b) Mostre o nome dos corretores que não realizaram nenhuma venda.
-- CONSULTA B:
SELECT c.nome
FROM corretores c
LEFT JOIN vendas v ON c.id = v.corretor_id
WHERE v.id IS NULL;

-- (c) Exiba o total de imóveis vendidos por cada corretor, ordenando do maior para o menor.
-- CONSULTA C:
SELECT c.nome AS corretor, COUNT(v.id) AS total_vendas
FROM corretores c
LEFT JOIN vendas v ON c.id = v.corretor_id
GROUP BY c.nome
ORDER BY total_vendas DESC;

-- (d) Liste os clientes que alugaram imóveis mais de uma vez, mostrando o nome e a quantidade de aluguéis.
-- CONSULTA D:
SELECT cl.nome AS cliente, COUNT(a.id) AS qtd_alugueis
FROM clientes cl
JOIN alugueis a ON cl.id = a.cliente_id
GROUP BY cl.nome
HAVING COUNT(a.id) > 1
ORDER BY qtd_alugueis DESC;

-- Atividade 3: Manipulação de Dados (20 pontos)
--    (a) Insira um novo imóvel para aluguel, associando a um proprietário já existente.
BEGIN; -- usar transação
-- proprietario_id por um existente (ex.: 1). 
-- Aqui usamos proprietario_id = 2.

INSERT INTO imoveis (endereco, bairro, valor_aluguel, disponivel_aluguel, proprietario_id)
VALUES ('Rua Nova, 77', 'Centro', 2100.00, TRUE, 2);

-- (b) Atualize o valor do aluguel de todos os imóveis localizados em um determinado bairro, aumentando em 10%.
--     Exemplo: bairro = 'Jardim'
UPDATE imoveis
SET valor_aluguel = ROUND(valor_aluguel * 1.10, 2)
WHERE bairro = 'Jardim';

-- (c) Remova todos os registros de aluguel com data anterior a 2020.
DELETE FROM alugueis
WHERE data_contrato < DATE '2020-01-01';

COMMIT; -- finaliza a transação das manipulações

-- Atividade 4: Segurança e Permissões (20 pontos)
--    (a) Revogue da role gerente a permissão de remover (DELETE) registros das tabelas.
REVOKE DELETE ON ALL TABLES IN SCHEMA public FROM gerente;

--    (b) Conceda ao usuário corretor permissão apenas de leitura (SELECT) sobre a tabela de clientes.
GRANT SELECT ON clientes TO corretor;