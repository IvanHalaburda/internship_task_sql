--
-- 1.вывести количество фильмов в каждой категории, отсортировать по убыванию.
--

select category.name,  count(film_id) AS number
from film_category
JOIN category ON film_category.category_id = category.category_id
group by category.name
order by number desc;

--
-- 2. вывести 10 актеров, чьи фильмы большего всего арендовали, отсортировать по убыванию.
--

select (select concat(actor.first_name, ' ', actor.last_name) as name from actor where actor.actor_id = film_actor.actor_id) , count(inventory.inventory_id) as number from inventory
join film_actor on inventory.film_id = film_actor.film_id
group by film_actor.actor_id
order by number desc
limit 10;

--
-- 3. вывести категорию фильмов, на которую потратили больше всего денег.
--

select category.name , sum(replacement_cost) as summa from film,film_category
join category on category.category_id = film_category.category_id
where film.film_id = film_category.film_id
group by category.name
order by summa desc
limit 1;

--
-- 4. вывести названия фильмов, которых нет в inventory. Написать запрос без использования оператора IN.
--

select title from film
left join inventory on  film.film_id = inventory.film_id
where inventory.film_id is null;

--
-- 5. вывести топ 3 актеров, которые больше всего появлялись в фильмах в категории “Children”.
-- Если у нескольких актеров одинаковое кол-во фильмов, вывести всех. (Мне не нравится 2 вложенных
-- запроса, но как сделать без них я ебу)
--

select dense_rank as rating, imya, number from
    (select dense_rank () OVER ( ORDER BY number desc) , imya, number from (
        select concat(actor.first_name, ' ', actor.last_name) as imya,
        count(category.name) as number from film_category
        join category ON film_category.category_id = category.category_id
        join film_actor on film_category.film_id = film_actor.film_id
        join actor on film_actor.actor_id = actor.actor_id
        where category.name = 'Children'
        group by imya
    ) as t) as k
where dense_rank < 4
order by number desc;

--
-- 6. вывести города с количеством активных и неактивных клиентов (активный — customer.active = 1).
-- Отсортировать по количеству неактивных клиентов по убыванию.(limit поставил, чтоб консоль не засоряло)
--

select city.city,
count(active) filter (where active = 0) as number_inactive,
count(active) filter (where active = 1) as number_active
from address
join city on address.city_id = city.city_id
full outer join customer on address.address_id = customer.address_id
group by city.city
order by number_inactive desc
limit 50;

--
-- 7. Вывести категорию фильмов, у которой самое большое кол-во часов суммарной аренды в городах
-- (customer.address_id в этом city), и которые начинаются на букву “a”.
-- То же самое сделать для городов в которых есть символ “-”. Написать все в одном запросе.
--

with t as ( select category.name,
sum(film.rental_duration) filter (where city.city like 'A%') as hours_a,
sum(film.rental_duration) filter (where city.city like '%-%') as hours_minus from film
join film_category on film.film_id = film_category.film_id
join category on film_category.category_id = category.category_id
join inventory on film.film_id = inventory.film_id
join rental on inventory.inventory_id = rental.inventory_id
join customer on rental.customer_id = customer.customer_id
full outer join address on customer.address_id = address.address_id
join city on address.city_id = city.city_id
group by category.name)
select name  from t
where hours_a = (select max(hours_a) from t) or hours_minus = (select max(hours_minus) from t);