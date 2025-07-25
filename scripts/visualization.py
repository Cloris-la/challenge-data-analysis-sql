import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import numpy as np
import os
import re
from plotly.io import write_html, write_image

# Ensure the plots folder exists
os.makedirs('plots', exist_ok=True)

def standardize_column_names(df):
    df.columns = df.columns.str.lower()
    df.columns = [re.sub(r'[^\w]', '_', col) for col in df.columns]
    df.columns = [re.sub(r'_+', '_', col) for col in df.columns]
    df.columns = [col.strip('_') for col in df.columns]
    return df

def save_plot(fig, filename):
    html_path = f'plots/{filename}.html'
    png_path = f'plots/{filename}.png'
    write_html(fig, html_path, auto_open=False)
    try:
        write_image(fig, png_path, scale=2)
        print(f"Saved static image: {png_path}")
    except Exception as e:
        print(f"Failed to save PNG: {e} (please ensure kaleido is installed)")
    print(f"Saved interactive chart: {html_path}")
    return html_path, png_path

# 1. Juridical Form Distribution
def visualize_juridical_form(df):
    if 'juridicalform' not in df.columns or 'percentage' not in df.columns:
        print("Error: DataFrame is missing required columns ('juridicalform', 'percentage')")
        return None
    fig = px.pie(df, names='juridicalform', values='percentage',
                 title='Distribution of Legal Entity Types', hole=0.4)
    fig.update_traces(textposition='inside', textinfo='percent+label')
    fig.update_layout(legend=dict(orientation="h", yanchor="bottom", y=-0.2))
    return save_plot(fig, 'juridical_form_distribution')

# 2. Company Status Distribution
def visualize_company_status(df):
    if 'status' not in df.columns or 'count' not in df.columns:
        print("Error: DataFrame is missing required columns ('status', 'count')")
        return None
    df = df.sort_values('count', ascending=True)
    fig = px.bar(df, y='status', x='count', title='Company Status Distribution',
                 color='status', text='count', orientation='h')
    fig.update_layout(yaxis_title="Status", xaxis_title="Number of Companies")
    return save_plot(fig, 'company_status_distribution')

# 3. Average Company Age by Industry
def visualize_company_age(df):
    if 'nacecode' not in df.columns or 'avg_company_age' not in df.columns:
        print("Error: DataFrame is missing required columns ('nacecode', 'avg_company_age')")
        return None
    df = df.rename(columns={'nacecode': 'nace_code'})
    df = df.sort_values('avg_company_age', ascending=False).head(20)
    fig = px.bar(df, x='nace_code', y='avg_company_age',
                 title='Average Company Age by Industry (Top 20)',
                 color='avg_company_age', color_continuous_scale='Viridis',
                 text='avg_company_age')
    fig.update_layout(xaxis_title="NACE Industry Code", yaxis_title="Average Age (Years)")
    return save_plot(fig, 'company_age_by_industry')

# 4. Company Creation Trends
def visualize_creation_trends(df):
    required_cols = ['year', 'new_companies', 'yoy_change']
    if not all(col in df.columns for col in required_cols):
        print(f"Error: DataFrame is missing required columns {required_cols}")
        return None
    fig = go.Figure()
    fig.add_trace(go.Scatter(x=df['year'], y=df['new_companies'],
                             mode='lines+markers', name='New Companies'))
    fig.add_trace(go.Bar(x=df['year'], y=df['yoy_change'],
                         name='YoY Change (%)',
                         marker_color=np.where(df['yoy_change'] > 0, '#2ca02c', '#d62727'),
                         yaxis='y2'))
    fig.update_layout(
        title='Annual Company Formation Trends',
        xaxis_title="Year",
        yaxis_title="New Companies Count",
        yaxis2=dict(title="Year-over-Year Change (%)", overlaying='y', side='right'),
        template='plotly_white',
        hovermode="x unified"
    )
    return save_plot(fig, 'company_creation_trends')

# 5. Geographical Distribution of Companies
def visualize_geo_distribution(df):
    required_cols = ['zipcode', 'company_count', 'percentage']
    if not all(col in df.columns for col in required_cols):
        print(f"Error: DataFrame is missing required columns {required_cols}")
        return None
    df = df.groupby('zipcode').agg({'company_count': 'sum', 'percentage': 'first'}).reset_index()
    df = df.sort_values('company_count', ascending=False).head(20)
    fig = px.treemap(df, path=['zipcode'], values='company_count',
                     title='Geographical Distribution of Companies (Top 20 Zip Codes)',
                     color='company_count', color_continuous_scale='Blues',
                     hover_data=['percentage'])
    fig.update_layout(margin=dict(t=50, l=25, r=25, b=25))
    return save_plot(fig, 'geographical_distribution')

# 6. Sector Growth Year-over-Year
def visualize_sector_growth(df):
    required_cols = ['year', 'sector_name', 'yoy_growth']
    if not all(col in df.columns for col in required_cols):
        print(f"Error: DataFrame is missing required columns {required_cols}")
        return None
    top_sectors = df.groupby('sector_name')['yoy_growth'].mean().nlargest(10).index
    filtered_df = df[df['sector_name'].isin(top_sectors)]
    fig = px.line(filtered_df, x='year', y='yoy_growth', color='sector_name',
                  title='Year-over-Year Growth Trends for Top 10 Sectors',
                  markers=True)
    fig.update_layout(xaxis_title="Year", yaxis_title="Growth Rate (%)")
    return save_plot(fig, 'sector_growth_yoy')

# 7. Overall Industry Growth (1970-2025)
def visualize_overall_growth(df):
    required_cols = ['sector_name', 'companies_1970', 'companies_1980', 'companies_1990',
                     'companies_2000', 'companies_2010', 'companies_2020', 'companies_2025']
    if not all(col in df.columns for col in required_cols):
        print(f"Error: DataFrame is missing required columns {required_cols}")
        return None
    categories = ['1970', '1980', '1990', '2000', '2010', '2020', '2025']
    fig = go.Figure()
    for idx, row in df.iterrows():
        fig.add_trace(go.Scatterpolar(
            r=[row[f'companies_{cat}'] for cat in categories],
            theta=categories, fill='toself', name=row['sector_name']))
    fig.update_layout(
        polar=dict(radialaxis=dict(visible=True, type="log")),
        title="Industry Growth Across Decades",
        showlegend=True)
    return save_plot(fig, 'overall_industry_growth')

# 8. Recent 10-Year Average Growth
def visualize_recent_growth(df):
    required_cols = ['sector_name', 'avg_yoy_growth_rate', 'min_growth_rate', 'max_growth_rate']
    if not all(col in df.columns for col in required_cols):
        print(f"Error: DataFrame is missing required columns {required_cols}")
        return None
    df = df.sort_values('avg_yoy_growth_rate', ascending=False)
    fig = px.box(df, x='sector_name', y='avg_yoy_growth_rate',
                 title='10-Year Average Growth Rate by Industry',
                 points="all", color='sector_name',
                 hover_data=['min_growth_rate', 'max_growth_rate'])
    fig.update_layout(xaxis_title="Industry Sector", yaxis_title="Average Growth Rate (%)", showlegend=False)
    return save_plot(fig, 'recent_growth_rates')

# 9. Emerging Industries Analysis
def visualize_emerging_industries(df):
    required_cols = ['sector_name', 'post_2000_percentage', 'companies_1990s', 'companies_2000s',
                     'companies_2010s', 'companies_2020s']
    if not all(col in df.columns for col in required_cols):
        print(f"Error: DataFrame is missing required columns {required_cols}")
        return None
    decades = ['1990s', '2000s', '2010s', '2020s']
    df = df.sort_values('post_2000_percentage', ascending=False).head(15)
    fig = go.Figure()
    for decade in decades:
        fig.add_trace(go.Bar(x=df['sector_name'], y=df[f'companies_{decade}'], name=decade))
    fig.update_layout(
        title='Emerging Industries (Post-2000 Dominance)',
        xaxis_title="Industry Sector", yaxis_title="Number of Companies", barmode='stack')
    return save_plot(fig, 'emerging_industries')

# 10. Invisible Champions Analysis
def visualize_invisible_champions(df):
    required_cols = ['sector_name', 'avg_annual_new_companies', 'avg_yoy_growth_rate',
                     'total_new_companies', 'market_avg_companies', 'market_avg_growth']
    if not all(col in df.columns for col in required_cols):
        print(f"Error: DataFrame is missing required columns {required_cols}")
        return None
    fig = px.scatter(df, x='avg_annual_new_companies', y='avg_yoy_growth_rate',
                     size='total_new_companies', color='sector_category',
                     hover_name='sector_name', title='Invisible Champions Analysis', size_max=60)
    avg_x = df['market_avg_companies'].mean()
    avg_y = df['market_avg_growth'].mean()
    fig.add_shape(type="line", x0=avg_x, y0=df['avg_yoy_growth_rate'].min(),
                  x1=avg_x, y1=df['avg_yoy_growth_rate'].max(),
                  line=dict(color="Red", width=2, dash="dash"))
    fig.add_shape(type="line", x0=df['avg_annual_new_companies'].min(), y0=avg_y,
                  x1=df['avg_annual_new_companies'].max(), y1=avg_y,
                  line=dict(color="Red", width=2, dash="dash"))
    fig.update_layout(xaxis_title="Average Annual New Companies", yaxis_title="Average Growth Rate (%)")
    return save_plot(fig, 'invisible_champions')

# 11. Cruel Industries Analysis
def visualize_cruel_industries(df):
    required_cols = ['sector_name', 'cessation_rate', 'recent_entry_rate', 'total_enterprises']
    if not all(col in df.columns for col in required_cols):
        print(f"Error: DataFrame is missing required columns {required_cols}")
        return None
    fig = px.scatter(df, x='cessation_rate', y='recent_entry_rate',
                     size='total_enterprises', color='competition_category',
                     hover_name='sector_name', title='Cruel Industries Analysis', size_max=60)
    fig.update_layout(xaxis_title="Business Cessation Rate (%)", yaxis_title="Recent Market Entry Rate (%)")
    return save_plot(fig, 'cruel_industries')

# 12. Industry Archetypes Comparison
def visualize_industry_archetypes(df):
    required_cols = ['industry_archetype', 'cessation_rate', 'recent_entry_rate', 'avg_company_age']
    if not all(col in df.columns for col in required_cols):
        print(f"Error: DataFrame is missing required columns {required_cols}")
        return None
    archetypes = df['industry_archetype'].unique()
    categories = ['cessation_rate', 'recent_entry_rate', 'avg_company_age']
    category_names = ['Cessation Rate', 'New Entry Rate', 'Average Age']
    fig = go.Figure()
    for archetype in archetypes:
        archetype_data = df[df['industry_archetype'] == archetype].iloc[0]
        values = [archetype_data[c] for c in categories]
        fig.add_trace(go.Scatterpolar(r=values, theta=category_names, fill='toself', name=archetype))
    fig.update_layout(
        polar=dict(radialaxis=dict(visible=True, range=[0, max(df[c].max() for c in categories)*1.2])),
        title="Industry Archetype Characteristics Comparison", showlegend=True)
    return save_plot(fig, 'industry_archetypes')

def main():
    print("Starting to generate visualizations...")
    data_files = {
        'juridical_form': 'juridical_form.csv',
        'company_status': 'company_status.csv',
        'company_age': 'company_age.csv',
        'creation_trends': 'creation_trends.csv',
        'geo_distribution': 'geo_distribution.csv',
        'sector_growth': 'sector_growth.csv',
        'overall_growth': 'overall_growth.csv',
        'recent_growth': 'recent_growth.csv',
        'emerging_industries': 'emerging_industries.csv',
        'invisible_champions': 'invisible_champions.csv',
        'cruel_industries': 'cruel_industries.csv',
        'industry_archetypes': 'industry_archetypes.csv'
    }
    data_frames = {}
    for name, file in data_files.items():
        try:
            df = pd.read_csv(f'data/{file}')
            data_frames[name] = standardize_column_names(df)
            print(f"Loaded: data/{file}")
        except Exception as e:
            print(f"Failed to load data/{file}: {e}")
            data_frames[name] = None
    print("Data loading complete, starting to generate charts...")
    if data_frames['juridical_form'] is not None:
        visualize_juridical_form(data_frames['juridical_form'])
    if data_frames['company_status'] is not None:
        visualize_company_status(data_frames['company_status'])
    if data_frames['company_age'] is not None:
        visualize_company_age(data_frames['company_age'])
    if data_frames['creation_trends'] is not None:
        visualize_creation_trends(data_frames['creation_trends'])
    if data_frames['geo_distribution'] is not None:
        visualize_geo_distribution(data_frames['geo_distribution'])
    if data_frames['sector_growth'] is not None:
        visualize_sector_growth(data_frames['sector_growth'])
    if data_frames['overall_growth'] is not None:
        visualize_overall_growth(data_frames['overall_growth'])
    if data_frames['recent_growth'] is not None:
        visualize_recent_growth(data_frames['recent_growth'])
    if data_frames['emerging_industries'] is not None:
        visualize_emerging_industries(data_frames['emerging_industries'])
    if data_frames['invisible_champions'] is not None:
        visualize_invisible_champions(data_frames['invisible_champions'])
    if data_frames['cruel_industries'] is not None:
        visualize_cruel_industries(data_frames['cruel_industries'])
    if data_frames['industry_archetypes'] is not None:
        visualize_industry_archetypes(data_frames['industry_archetypes'])
    print("All charts have been generated and saved in the plots/ folder.")

if __name__ == "__main__":
    main()