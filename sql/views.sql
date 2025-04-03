-- USE database_name;

-- ---------------------------
-- DASHBOARD VIEWS SECTION
-- ---------------------------

-- VIEW 1: vw_active_sponsored_owners
-- Description: Lists all owners with currently active sponsorships.
CREATE VIEW vw_active_sponsored_owners AS
SELECT osp.id_owner_sponsor_plan,
       o.id_owner,
       o.owner_name,
       sp.id_sponsor_plan,
       s.nameSponsor,
       osp.start_date,
       osp.end_date
FROM owner_sponsor_plan osp
JOIN owner o ON osp.owner_id = o.id_owner
JOIN sponsor_plan sp ON osp.sponsor_plan_id = sp.id_sponsor_plan
JOIN sponsor s ON sp.sponsor_id = s.id_sponsor
WHERE NOW() BETWEEN osp.start_date AND osp.end_date;


-- VIEW 2: vw_all_sponsored_owners
-- Description: Lists all owners who have ever been sponsored, regardless of sponsorship status.
CREATE VIEW vw_all_sponsored_owners AS
SELECT 
  osp.id_owner_sponsor_plan,
  o.id_owner,
  o.owner_name,
  sp.id_sponsor_plan,
  s.nameSponsor,
  osp.start_date,
  osp.end_date
FROM owner_sponsor_plan osp
JOIN owner o ON osp.owner_id = o.id_owner
JOIN sponsor_plan sp ON osp.sponsor_plan_id = sp.id_sponsor_plan
JOIN sponsor s ON sp.sponsor_id = s.id_sponsor;


-- VIEW 3: vw_store_impact
-- Description: Shows how many stores each owner created during their sponsorship period.
CREATE VIEW vw_store_impact AS
SELECT osp.id_owner_sponsor_plan,
       osp.owner_id,
       COUNT(st.id_store) AS total_created_stores
FROM owner_sponsor_plan osp
LEFT JOIN store st ON st.owner_id = osp.owner_id
                AND st.store_creation_date BETWEEN osp.start_date AND osp.end_date
GROUP BY osp.id_owner_sponsor_plan, osp.owner_id;


-- VIEW 4: vw_user_impact
-- Description: Shows how many users were invited by each owner during their sponsorship period.
CREATE VIEW vw_user_impact AS
SELECT osp.id_owner_sponsor_plan,
       osp.owner_id,
       COUNT(u.id_user) AS total_invited_users
FROM owner_sponsor_plan osp
LEFT JOIN users u ON u.owner_id = osp.owner_id
                AND u.user_date BETWEEN osp.start_date AND osp.end_date
GROUP BY osp.id_owner_sponsor_plan, osp.owner_id;


-- VIEW 5: vw_community_impact
-- Description: Shows how many communities each owner created during their sponsorship period.
CREATE VIEW vw_community_impact AS
SELECT osp.id_owner_sponsor_plan,
       osp.owner_id,
       COUNT(c.id_community) AS total_created_communities
FROM owner_sponsor_plan osp
LEFT JOIN community c ON c.owner_id = osp.owner_id
                    AND c.community_creation_date BETWEEN osp.start_date AND osp.end_date
GROUP BY osp.id_owner_sponsor_plan, osp.owner_id;


-- VIEW 6: vw_total_impacted_users
-- Description: Calculates the total number of impacted users (users invited + users in joined communities),
-- ensuring each user is counted only once.
CREATE VIEW vw_total_impacted_users AS
SELECT 
  osp.id_owner_sponsor_plan,
  osp.owner_id,
  COUNT(DISTINCT u_final.id_user) AS total_impacted_users
FROM owner_sponsor_plan osp
LEFT JOIN users u_final ON u_final.owner_id = osp.owner_id
                        AND u_final.user_date BETWEEN osp.start_date AND osp.end_date
LEFT JOIN owner_community oc ON oc.owner_id = osp.owner_id
LEFT JOIN usuario_community uc ON uc.community_id = oc.community_id
LEFT JOIN users u2 ON u2.id_user = uc.user_id
                   AND u2.user_date BETWEEN osp.start_date AND osp.end_date
GROUP BY osp.id_owner_sponsor_plan, osp.owner_id;


