-- USE database_name;

-- Trigger: Prevents inserting a new sponsorship with dates that overlap an existing one for the same owner
-- Trigger: Impede inserir um novo patrocínio com datas que se sobrepõem a outro já existente para o mesmo owner 
DELIMITER //

CREATE TRIGGER trg_prevent_overlap_insert
BEFORE INSERT ON owner_sponsor_plan
FOR EACH ROW
BEGIN
  DECLARE conflict_count INT;

  SELECT COUNT(*) INTO conflict_count
  FROM owner_sponsor_plan
  WHERE owner_id = NEW.owner_id
    AND NEW.start_date <= end_date
    AND NEW.end_date >= start_date;

  IF conflict_count > 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Conflito: este owner já possui patrocínio ativo neste intervalo.';
  END IF;
END;
//


-- Trigger: Prevents updating sponsorship dates in a way that causes conflicts with another existing sponsorship
-- Trigger: Impede atualizar as datas de um patrocínio de forma que passe a conflitar com outro patrocínio já existente
CREATE TRIGGER trg_prevent_overlap_update
BEFORE UPDATE ON owner_sponsor_plan
FOR EACH ROW
BEGIN
  DECLARE conflict_count INT;

  SELECT COUNT(*) INTO conflict_count
  FROM owner_sponsor_plan
  WHERE owner_id = NEW.owner_id
    AND id_owner_sponsor_plan != OLD.id_owner_sponsor_plan
    AND NEW.start_date <= end_date
    AND NEW.end_date >= start_date;

  IF conflict_count > 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Conflito: este owner já possui outro patrocínio ativo no período informado.';
  END IF;
END;
//

DELIMITER ;


-- Trigger: Automatically sets expiration_date (+3 days
-- Trigger: Define expiration_date automaticamente (+3 dias)
DELIMITER //
CREATE TRIGGER trg_set_expiration_date
BEFORE INSERT ON sponsorship_selection
FOR EACH ROW
BEGIN
    SET NEW.expiration_date = DATE_ADD(NOW(), INTERVAL 3 DAY);
END;
//

-- Trigger: Decreases available slots when a selection is inserted
-- Trigger: Decrementa vagas ao inserir seleção
CREATE TRIGGER trg_decrement_slot_on_insert
AFTER INSERT ON sponsorship_selection
FOR EACH ROW
BEGIN
    UPDATE sponsorship_slot
    SET slot_quantity_available = slot_quantity_available - 1
    WHERE id_slot = NEW.slot_id;
END;
//

-- Trigger: Increases available slots if a selection is deleted and was approved
-- Trigger: Incrementa vagas se seleção for deletada e aprovada
CREATE TRIGGER trg_increment_slot_on_delete
BEFORE DELETE ON sponsorship_selection
FOR EACH ROW
BEGIN
    IF OLD.status_selection = 'approved' THEN
        UPDATE sponsorship_slot
        SET slot_quantity_available = slot_quantity_available + 1
        WHERE id_slot = OLD.slot_id;
    END IF;
END;
//

-- Trigger: Prevents a new registration with the same CPF within 30 days
-- Trigger : Impede novo cadastro com mesmo CPF em menos de 30 dias
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
//


-- Enables the Event Scheduler
-- Ativa o Event Scheduler
SET GLOBAL event_scheduler = ON;

-- Event Scheduler: automatically rejects expired selections
-- Event Scheduler: rejeita automaticamente seleções expiradas
CREATE EVENT IF NOT EXISTS ev_auto_reject_expired
ON SCHEDULE EVERY 1 HOUR
DO
  UPDATE sponsorship_selection
  SET status_selection = 'rejected'
  WHERE status_selection = 'pending' AND expiration_date < NOW();
//

DELIMITER ;