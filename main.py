import streamlit as st

# 1. Настройка страницы
st.set_page_config(
    page_title="E-Commerce Customer Analytics",
    page_icon="📊",
    layout="wide"
)

st.title("📊 Аналитика сегментации клиентов E-Commerce")

# 2. Инициализация подключения к PostgreSQL из secrets.toml
conn = st.connection("postgresql", type="sql")

# 3. Разделение интерфейса на удобные вкладки
tab1, tab2, tab3, tab4 = st.tabs([
    "📈 Общий обзор и KPI",
    "👥 Демография и Возраст",
    "🌍 География и Доходы",
    "⭐ VIP & Сегменты"
])

# -------------------------------------------------------------------
# ВКЛАДКА 1: ОБЩИЙ ОБЗОР И KPI
# -------------------------------------------------------------------
with tab1:
    st.header("Ключевые показатели (AOV и Траты)")

    # Запрос общих статистик по AOV и spent
    kpi_query = """
        SELECT 
            MIN(avg_order_value_usd) AS min_aov,
            MAX(avg_order_value_usd) AS max_aov,
            ROUND(AVG(avg_order_value_usd)::numeric, 2) AS avg_aov,
            ROUND(STDDEV(avg_order_value_usd)::numeric, 2) AS stddev_aov,
            MIN(total_spent_usd) AS min_spent,
            MAX(total_spent_usd) AS max_spent
        FROM public.e_commerce_customer_segmentation;
    """
    df_kpi = conn.query(kpi_query, ttl="10m")

    # Отображение ключевых метрик в карточках
    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Средний чек (AOV)", f"${df_kpi['avg_aov'][0]}")
    c2.metric("Мин. чек / Макс. чек", f"${df_kpi['min_aov'][0]} / ${df_kpi['max_aov'][0]}")
    c3.metric("Макс. сумма трат", f"${df_kpi['max_spent'][0]:,.2f}")
    c4.metric("Станд. отклонение AOV", f"${df_kpi['stddev_aov'][0]}")

    st.divider()

    st.subheader("Сравнение существующих сегментов")
    segments_query = """
        SELECT 
            customer_segment,
            COUNT(customer_id) AS total_clients,
            ROUND(AVG(age)::numeric, 1) AS avg_age,
            ROUND(AVG(total_purchases)::numeric, 1) AS avg_purchases,
            ROUND(AVG(avg_order_value_usd)::numeric, 2) AS avg_check,
            ROUND(SUM(total_spent_usd)::numeric, 2) AS total_revenue
        FROM public.e_commerce_customer_segmentation
        GROUP BY customer_segment
        ORDER BY total_revenue DESC;
    """
    df_segments = conn.query(segments_query, ttl="10m")

    # Вывод таблицы и стандартного графика Streamlit
    col_table, col_chart = st.columns([3, 2])
    with col_table:
        st.dataframe(df_segments, use_container_width=True)
    with col_chart:
        st.bar_chart(df_segments.set_index("customer_segment")["total_revenue"])

# -------------------------------------------------------------------
# ВКЛАДКА 2: ДЕМОГРАФИЯ И ВОЗРАСТ
# -------------------------------------------------------------------
with tab2:
    st.header("Возрастные группы и Гендерный анализ")

    st.subheader("Жиынтық статистика (Возрастные группы)")
    age_group_query = """
        SELECT 
            CASE 
                WHEN age BETWEEN 18 AND 24 THEN '1. Gen-Z (18-24)'
                WHEN age BETWEEN 25 AND 38 THEN '2. Young Adults (25-38)'
                WHEN age BETWEEN 39 AND 55 THEN '3. Middle Aged (39-55)'
                WHEN age >= 56 THEN '4. Seniors (56+)'
                ELSE '5. Unknown'
            END AS age_group,
            COUNT(customer_id) AS total_customers,
            ROUND(AVG(total_purchases)::numeric, 2) AS avg_purchases_per_client,
            ROUND(AVG(avg_order_value_usd)::numeric, 2) AS avg_order_value,
            ROUND(SUM(total_spent_usd)::numeric, 2) AS total_revenue
        FROM public.e_commerce_customer_segmentation
        GROUP BY 1
        ORDER BY age_group;
    """
    df_age_groups = conn.query(age_group_query, ttl="10m")
    st.dataframe(df_age_groups, use_container_width=True)

    st.subheader("Мужчины и Женщины внутри возрастных групп")
    gender_age_query = """
        SELECT 
            CASE 
                WHEN age BETWEEN 18 AND 24 THEN '1. Gen-Z (18-24)'
                WHEN age BETWEEN 25 AND 38 THEN '2. Young Adults (25-38)'
                WHEN age BETWEEN 39 AND 55 THEN '3. Middle Aged (39-55)'
                WHEN age >= 56 THEN '4. Seniors (56+)'
                ELSE '5. Other'
            END AS age_group,
            gender,
            COUNT(customer_id) AS total_customers,
            ROUND(AVG(total_purchases)::numeric, 1) AS avg_purchases,
            ROUND(AVG(avg_order_value_usd)::numeric, 2) AS avg_order_value,
            ROUND(SUM(total_spent_usd)::numeric, 2) AS total_revenue
        FROM public.e_commerce_customer_segmentation
        GROUP BY 1, gender
        ORDER BY age_group, gender;
    """
    df_gender_age = conn.query(gender_age_query, ttl="10m")
    st.dataframe(df_gender_age, use_container_width=True)

# -------------------------------------------------------------------
# ВКЛАДКА 3: ГЕОГРАФИЯ И ДОХОДЫ
# -------------------------------------------------------------------
with tab3:
    st.header("География и Доходные категории")

    col_geo, col_inc = st.columns(2)

    with col_geo:
        st.subheader("Топ-5 стран по общей выручке")
        top_countries_query = """
            SELECT 
                country,
                COUNT(customer_id) AS total_customers,
                SUM(total_purchases) AS total_orders,
                ROUND(AVG(avg_order_value_usd)::numeric, 2) AS avg_order_value,
                ROUND(SUM(total_spent_usd)::numeric, 2) AS total_revenue
            FROM public.e_commerce_customer_segmentation
            GROUP BY country
            ORDER BY total_revenue DESC
            LIMIT 5;
        """
        df_countries = conn.query(top_countries_query, ttl="10m")
        st.dataframe(df_countries, use_container_width=True)
        st.bar_chart(df_countries.set_index("country")["total_revenue"])

    with col_inc:
        st.subheader("Анализ по уровню доходов (Income Bracket)")
        income_query = """
            SELECT 
                income_bracket,
                COUNT(customer_id) AS total_customers,
                ROUND(AVG(avg_order_value_usd)::numeric, 2) AS avg_check,
                ROUND(AVG(total_spent_usd)::numeric, 2) AS avg_total_spent
            FROM public.e_commerce_customer_segmentation
            GROUP BY income_bracket
            ORDER BY avg_total_spent DESC;
        """
        df_income = conn.query(income_query, ttl="10m")
        st.dataframe(df_income, use_container_width=True)

# -------------------------------------------------------------------
# ВКЛАДКА 4: VIP И ДЕТАЛЬНАЯ ВЫБОРКА
# -------------------------------------------------------------------
with tab4:
    st.header("VIP-клиенты (Топ 1% по тратам)")
    vip_query = """
        SELECT 
            customer_id,
            age,
            gender,
            country,
            city,
            income_bracket,
            total_purchases,
            avg_order_value_usd,
            total_spent_usd,
            customer_segment
        FROM public.e_commerce_customer_segmentation
        WHERE total_spent_usd >= (
            SELECT PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_spent_usd)
            FROM public.e_commerce_customer_segmentation
        )
        ORDER BY total_spent_usd DESC;
    """
    df_vip = conn.query(vip_query, ttl="5m")

    st.metric("Количество VIP-клиентов", len(df_vip))
    st.dataframe(df_vip, use_container_width=True)

    # Кнопка скачивания VIP-списка в CSV
    csv_data = df_vip.to_csv(index=False).encode('utf-8')
    st.download_button(
        label="📥 Скачать VIP-клиентов (CSV)",
        data=csv_data,
        file_name="vip_customers.csv",
        mime="text/csv"
    )