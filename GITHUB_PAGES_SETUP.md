# GitHub Pages Setup Instructions

Follow these steps to publish your dbt documentation on GitHub Pages:

## 1. Enable GitHub Pages

1. Go to your GitHub repository: `https://github.com/[YOUR_USERNAME]/divvybikes-share-success`
2. Click on **Settings** tab
3. Scroll down to **Pages** section in the left sidebar
4. Under **Source**, select:
   - **Deploy from a branch**
   - Branch: `main`
   - Folder: `/ (root)`

## 2. Push Your Changes

Make sure you've committed and pushed all the recent changes:

```bash
git add .
git commit -m "Add GitHub Pages deployment for dbt documentation"
git push origin main
```

## 3. Trigger the Workflow

The GitHub Actions workflow will automatically trigger when you push changes to the `dbt_divvy/` directory. You can also manually trigger it:

1. Go to **Actions** tab in your repository
2. Click on **Deploy dbt Documentation to GitHub Pages**
3. Click **Run workflow** button

## 4. Access Your Documentation

Once the workflow completes (usually 2-5 minutes), your documentation will be available at:

```
https://[YOUR_USERNAME].github.io/divvybikes-share-success/
```

The landing page will show:
- Project overview with key statistics
- Direct link to dbt documentation
- Data lineage and model relationships

## 5. Update README.md

The README.md has been updated with:
- ✅ Project status badge showing "complete"
- 📊 Prominent link to live documentation
- 🎯 Key achievements and statistics

## Troubleshooting

- **Workflow fails**: Check the Actions tab for error details
- **404 error**: Ensure GitHub Pages is enabled and pointing to the right source
- **Documentation not updating**: The workflow triggers on changes to `dbt_divvy/` directory

## What's Included

Your GitHub Pages site includes:
- **Welcome page** (`welcome.html`) with project statistics
- **Full dbt documentation** with data lineage graphs
- **Model details** for all 8 models across Bronze → Silver → Gold → Marts
- **Test results** showing 97% success rate (33/34 tests passed)
- **Data quality insights** from 335K+ trip records
