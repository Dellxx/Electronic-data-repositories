1. Аудитория өзегі (Ең көп кездесетін жас пен жыныс)
Жынысы мен жас тобы бойынша негізгі клиенттерді анықтау

Өмірде не үшін керек: Брендтің «бейнесі» кім екенін білу үшін. Егер біз 25–34 жас аралығындағы әйелдердің ең көп екенін көрсек, барлық баннерлер мен Instagram жарнамаларын соларға бейімдеп жасаймыз.

SQL
SELECT 
    gender,
    age_group,
    COUNT(customer_id) AS total_customers,
    ROUND(COUNT(customer_id) * 100.0 / (SELECT COUNT(*) FROM demographics), 2) AS percentage_share
FROM demographics
GROUP BY gender, age_group
ORDER BY total_customers DESC;
Оқытушыға арналған түсіндірме: Бұл сұраныс қай жыныс пен жас тобы базада пайыздық тұрғыдан басым екенін көрсетеді (percentage_share). GROUP BY арқылы топтап, ең көп клиенті бар ядроны (ORDER BY DESC) бірінші орынға шығарамыз.

2. Премиум сегментті табу (Табысы жоғары клиенттер)
Табыс деңгейі (income_bracket) бойынша сегментация

Өмірде не үшін керек: Қымбат тауарлар мен люкс брендтерді кімге сату керектігін анықтау үшін. Оларға жаппай жеңілдік емес, VIP-мәртебе мен арнайы қызмет ұсыну маңызды.

SQL
SELECT 
    income_bracket,
    COUNT(customer_id) AS customer_count
FROM demographics
WHERE income_bracket IN ('High', 'Upper-Middle')
GROUP BY income_bracket
ORDER BY customer_count DESC;
Оқытушыға арналған түсіндірме: WHERE сүзгісі арқылы тек жоғары табысты (High, Upper-Middle) клиенттерді бөліп алып, солардың санын есептейміз. Бұл нақты бір сегментке жарнама бюджетін тиімді жұмсауға көмектеседі.

3. Отбасылы клиенттерге арналған кросс-маркетинг
Отбасы жағдайы (marital_status) мен табысты байланыстыру

Өмірде не үшін керек: Үйленген немесе отбасы бар адамдар көбірек ақша жұмсайды (балаларға, үйге қажетті тауарлар). Оларға «екеуін алсаң — біреуі тегін» немесе «отбасылық топтама» сияқты науқандарды ұсынуға болады.

SQL
SELECT 
    marital_status,
    income_bracket,
    COUNT(customer_id) AS customer_count,
    ROUND(AVG(age), 1) AS avg_age
FROM demographics
GROUP BY marital_status, income_bracket
ORDER BY customer_count DESC;
Оқытушыға арналған түсіндірме: Бұл сұраныс отбасылық жағдай мен табыс деңгейін қиылыстырып, олардың орташа жасын есептейді. Маркетологтар осы арқылы «үйленген орта таптың жасы шамамен қаншада» екенін нақты біле алады.

4. Жас мамандар мен студенттер сегменті (Бюджеттік аудитория)
Жас аралығы (мысалы, 18–25 жас) және төменгі табыс деңгейі

Өмірде не үшін керек: Олардың қазір қаражаты шектеулі болуы мүмкін, бірақ олар — болашақ тұрақты клиенттер. Оларға студенттік жеңілдіктер немесе әлеуметтік желі арқылы қолжетімді ұсыныстар жасаймыз.

SQL
SELECT 
    age_group,
    income_bracket,
    COUNT(customer_id) AS young_budget_users
FROM demographics
WHERE age BETWEEN 18 AND 25
GROUP BY age_group, income_bracket
ORDER BY young_budget_users DESC;
Оқытушыға арналған түсіндірме: WHERE age BETWEEN 18 AND 25 арқылы тек жастарды іріктеп алып, олардың табыс санаттары бойынша қалай бөлінгенін көреміз.

5. Аудиторияны жас топтары бойынша теңгерімді бөлу (Age Diversity)
Барлық жас топтарының (age_group) жалпы аудиториядағы үлесі

Өмірде не үшін керек: Компания бір ғана жас тобына тәуелді болып қалмауы үшін (мысалы, тек жастар не тек егде адамдар), барлық топтардың тепе-теңдігін бақылап отыру қажет.

SQL
SELECT 
    age_group,
    COUNT(customer_id) AS total_users,
    ROUND(COUNT(customer_id) * 100.0 / (SELECT COUNT(*) FROM demographics), 2) AS share_percentage
FROM demographics
GROUP BY age_group
ORDER BY age_group ASC;
Оқытушыға арналған түсіндірме: Бұл сұраныс клиенттердің жас топтары бойынша қалай таралғанын пайызымен көрсетіп, ORDER BY age_group ASC арқылы жас санаттарын ретімен (кішіден үлкенге қарай) тізіп шығады.
