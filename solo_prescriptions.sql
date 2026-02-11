-- 1a. Which prescriber had the highest total number of claims (totaled over all drugs)? 
--      Report the npi and the total number of claims.

SELECT prescription.npi AS provider, SUM(total_claim_count) AS claim_count
FROM prescription
GROUP BY provider
ORDER BY claim_count DESC;

-- 1b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,
-- 		specialty_description, and the total number of claims.

SELECT prescriber.nppes_provider_first_name AS provider_first, prescriber.nppes_provider_last_org_name AS provider_last, prescriber.specialty_description AS specialty, SUM(total_claim_count) AS claim_count
FROM prescriber
JOIN prescription
on prescription.npi = prescriber.npi
GROUP BY provider_first, provider_last, specialty
ORDER BY claim_count DESC;
----------------SARAH------------------------
SELECT nppes_provider_first_name 
	, nppes_provider_last_org_name
	, specialty_description
	, SUM(total_claim_count) AS total_claims
	FROM prescription
	INNER JOIN prescriber
	USING(npi)
	GROUP BY nppes_provider_first_name 
	, nppes_provider_last_org_name
	, specialty_description
	ORDER BY total_claims DESC;

	
-- 2a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT prescriber.specialty_description AS specialty, SUM(total_claim_count) AS claim_count
FROM prescriber
JOIN prescription
on prescription.npi = prescriber.npi
GROUP BY specialty
ORDER BY claim_count DESC;

-- 2b. Which specialty had the most total number of claims for opioids?

select doc.specialty_description, sum(rx.total_claim_count) as claims
from prescription as rx
inner join drug
on rx.drug_name = drug.drug_name
inner join prescriber as doc
on doc.npi = rx.npi
WHERE drug.opioid_drug_flag = 'Y'
GROUP BY doc.specialty_description
ORDER BY claims DESC;

-- 2c. Challenge Question: Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

select distinct doc.specialty_description
from prescriber as doc
left join prescription as rx
on doc.npi = rx.npi
where rx.npi is null
order by doc.specialty_description ASC;

------------------Avery------smart one---------
SELECT specialty_description, COUNT(prescription.*) AS total_prescriptions
FROM prescriber
FULL JOIN prescription
USING (npi)
GROUP BY specialty_description
HAVING COUNT(prescription.*) = 0;


-- select distinct specialty_description
-- from prescriber
-- order by specialty_description ASC;


-- d. Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty,
-- 	report the percentage of total claims by that specialty which are for opioids. Which specialties 
-- 	have a high percentage of opioids?
select specialty_description, round(sum(case when opioid_drug_flag = 'Y' then prescription.total_claim_count end)/SUM(total_claim_count),3)*100 as opioid_pct
from prescription
inner join prescriber
using(npi)
inner join drug
on prescription.drug_name = drug.drug_name
group by specialty_description
order by opioid_pct desc nulls last;
	



-- 3a. Which drug (generic_name) had the highest total drug cost?
select drug.generic_name, rx.total_drug_cost as cost
from drug 
inner join prescription as rx
using(drug_name)
order by cost DESC
limit 1;

select generic_name, sum(rx.total_drug_count) as drug_money
from drug as d
inner join prescription as rx
using(drug_name)
group by generic_name
order by drug_money desc

-- 3b. Which drug (generic_name) has the hightest total cost per day? Bonus: 
-- Round your cost per day column to 2 decimal places. Google ROUND to see how this works.

select generic_name, round(sum(total_drug_cost) / sum(total_day_supply),2)::money as drug_cost_day
from drug as d
inner join prescription as rx
using(drug_name)
group by generic_name
order by drug_cost_day desc;


select drug.generic_name, round((rx.total_drug_cost/rx.total_day_supply),2) as per_day
from prescription as rx
join drug
using(drug_name)
order by per_day DESC;


-- 4a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. Hint: You may want to use a CASE expression for this.
select drug_name,
	case
		when opioid_drug_flag = 'Y' then 'opioid'
		when antibiotic_drug_flag = 'Y' then 'antibiotic'
		else 'neither'
	end as drug_type
from drug;


-- 4b. Building off of the query you wrote for part a, determine whether more was 
-- 		spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
select
    case
        when d.opioid_drug_flag = 'Y' THEN 'opioid'
        when d.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
    END AS drug_type,
    sum(p.total_drug_cost)::money AS total_spent
FROM drug d
JOIN prescription as p
ON p.drug_name = d.drug_name
WHERE d.opioid_drug_flag = 'Y' OR d.antibiotic_drug_flag = 'Y'
GROUP BY drug_type;



-- 5a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.
select count(distinct(cbsa))
from cbsa
join fips_county
using(fipscounty)
where fips_county.state = 'TN';


-- 5b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
select * from cbsa;
select * from population;

-- gets the new table - limits 1 DESC giving highest pop
select c.cbsaname, sum(p.population) as combined_pop
from population as p
join cbsa as c
using(fipscounty)
group by c.cbsaname
order by combined_pop desc
limit 1;
-- gets the new table - limits 1 ASC giving lowest pop
select c.cbsaname, sum(p.population) as combined_pop
from population as p
join cbsa as c
using(fipscounty)
group by c.cbsaname
order by combined_pop asc
limit 1;


-- 5c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
select * from cbsa;
select * from population;
select * from fips_county;

select fips_county.county, x.population
from (select *
		from cbsa
		right join population
		using(fipscounty)
		where cbsa is null) as x
join fips_county
using(fipscounty)
order by x.population desc
limit 1;


-- SELECT
--     f.county,
--     p.population
-- FROM population as p
-- left JOIN cbsa as c
--     USING (fipscounty)
-- JOIN fips_county as f
--     USING (fipscounty)
-- WHERE c.fipscounty IS NULL
-- ORDER BY p.population DESC
-- LIMIT 1;



-- 6a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
select * from prescription;

select p.drug_name, total_claim_count
from prescription as p
where total_claim_count >= 3000;

-- 6b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
select rx.drug_name, rx.total_claim_count,
	case
		when d.opioid_drug_flag = 'Y' then 'opioid'
		else '---'
	end as is_opioid
from prescription as rx
join drug as d
using(drug_name)
where rx.total_claim_count >= 3000;

-- 6c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
select rx.drug_name, rx.total_claim_count, doc.nppes_provider_first_name as first_name, doc.nppes_provider_last_org_name as last_name,
	case
		when d.opioid_drug_flag = 'Y' then 'opioid'
		else 'not opioid'
	end as is_opioid
from drug as d
join prescription as rx
using(drug_name)
join prescriber as doc
using(npi)
where rx.total_claim_count >= 3000;


-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. Hint: The results from all 3 parts will have 637 rows.

-- a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). Warning: Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
select npi from prescriber as rx;
select * from drug as d;

select doc.npi, d.drug_name 
from prescriber as doc
cross join drug as d
where doc.specialty_description = 'Pain Management' and doc.nppes_provider_city = 'NASHVILLE' and d.opioid_drug_flag = 'Y';

-- b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

select doc.npi, d.drug_name, rx.total_claim_count
from prescriber as doc
cross join drug as d
left join prescription as rx
using(npi, drug_name)
where doc.specialty_description = 'Pain Management' and doc.nppes_provider_city = 'NASHVILLE' and d.opioid_drug_flag = 'Y';

-- c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

select doc.npi, d.drug_name, coalesce(rx.total_claim_count,0) as total_claims
from prescriber as doc
cross join drug as d
left join prescription as rx
using(npi, drug_name)
where doc.specialty_description = 'Pain Management' and doc.nppes_provider_city = 'NASHVILLE' and d.opioid_drug_flag = 'Y'
order by total_claims desc;






-- ****************************************************************** --
-- WITH opioids AS (
-- 	SELECT drug_name as drug_name, opioid_drug_flag as opioid
-- 	from drug
-- 	where opioid_drug_flag = 'Y'
-- )
-- select specialty_description, sum(total_claim_count)
-- from prescribers

-- SELECT drug_name as drug_name, opioid_drug_flag as opioid
-- from drug
-- where opioid_drug_flag = 'Y'

-- SELECT prescriber.specialty_description AS specialty, SUM(total_claim_count) AS claim_count
-- FROM prescriber
-- JOIN prescription
-- on prescription.npi = prescriber.npi
-- GROUP BY specialty
-- ORDER BY claim_count DESC;

---------------------------------------------
-- SELECT prescription.npi AS provider, SUM(total_claim_count) AS claim_count
-- FROM prescription
-- JOIN prescriber
-- ON prescription.npi = prescriber.npi
-- GROUP BY provider
-- ORDER BY claim_count DESC;

-- SELECT prescriber.nppes_provider_last_org_name AS provider, SUM(total_claim_count) AS claim_count
-- FROM prescription
-- JOIN prescriber
-- ON prescription.npi = prescriber.npi
-- GROUP BY provider
-- ORDER BY claim_count DESC;



select nppes_provider_last_org_name, nppes_provider_first_name, nppes_provider_city,nppes_provider_state
from prescriber
where npi = 1881634483