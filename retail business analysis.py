
# Retail Business Performance & Profitability Analysis
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np

# ⿡ Load Datasets
sales = pd.read_csv("sales.csv")
products = pd.read_csv("products.csv")
inventory = pd.read_csv("inventory.csv")
stores = pd.read_csv("stores.csv")
date_dim = pd.read_csv("date_dim.csv")

# ⿢ Merge datasets (sales + product + store + inventory)
df = sales.merge(products, on="product_id", how="left") \
          .merge(stores, on="store_id", how="left") \
          .merge(date_dim, left_on="order_date", right_on="date", how="left") \
          .merge(inventory, on=["product_id", "store_id"], how="left")

# ⿣ Clean missing values
df.fillna({
    "brand": "Unknown",
    "region": "Unknown",
    "discount": 0,
    "avg_cost": 0,
    "on_hand_qty": 0
}, inplace=True)

# ⿤ Calculate metrics
df["profit_margin_pct"] = (df["profit"] / df["revenue"]) * 100
df["inventory_value"] = df["on_hand_qty"] * df["avg_cost"]

# Inventory days proxy (avg_stock / daily_sales)
sales_per_product = df.groupby("product_id")["quantity"].sum().reset_index()
inv_per_product = df.groupby("product_id")["on_hand_qty"].mean().reset_index()
inventory_days = inv_per_product.merge(sales_per_product, on="product_id", how="left")
inventory_days["inventory_days"] = inventory_days["on_hand_qty"] / (inventory_days["quantity"] / 30)
df = df.merge(inventory_days[["product_id", "inventory_days"]], on="product_id", how="left")

# ⿥ Correlation between inventory days & profitability
corr = df[["inventory_days", "profit_margin_pct"]].corr().iloc[0,1]
print(f"📊 Correlation between Inventory Days and Profit Margin: {corr:.2f}")

# ⿦ Category-level profit summary
category_summary = (
    df.groupby(["category", "sub_category"])
      .agg(total_revenue=("revenue","sum"),
           total_profit=("profit","sum"),
           avg_margin=("profit_margin_pct","mean"),
           avg_inventory_days=("inventory_days","mean"))
      .reset_index()
)
print("\n🧾 Category Summary:")
print(category_summary.head())

# ⿧ Visualization Section
sns.set(style="whitegrid", palette="coolwarm")

# Profit Margin vs Inventory Days (Scatter)
plt.figure(figsize=(8,6))
sns.scatterplot(data=df, x="inventory_days", y="profit_margin_pct", hue="category", alpha=0.7)
plt.title("Inventory Days vs Profit Margin by Category")
plt.xlabel("Inventory Days")
plt.ylabel("Profit Margin (%)")
plt.tight_layout()
plt.show()

# Average Margin by Category
plt.figure(figsize=(8,5))
sns.barplot(data=category_summary.sort_values("avg_margin", ascending=False),
            x="category", y="avg_margin", palette="viridis")
plt.title("Average Profit Margin by Category")
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()

# ⿨ Export Cleaned Data for Power BI
category_summary.to_csv("category_summary.csv", index=False)
df.to_csv("cleaned_retail_data.csv", index=False)

print("\n✅ Files exported:")
print("  • category_summary.csv  (for Power BI visuals)")
print("  • cleaned_retail_data.csv  (for deeper analysis)")

