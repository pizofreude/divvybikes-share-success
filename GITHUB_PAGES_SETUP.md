# GitHub Pages Setup Instructions

Follow these steps to publish your dbt documentation on GitHub Pages using GitHub Actions:

## 1. Enable GitHub Pages with GitHub Actions

1. Go to your GitHub repository: `https://github.com/[YOUR_USERNAME]/divvybikes-share-success`
2. Click on **Settings** tab
3. Scroll down to **Pages** section in the left sidebar
4. Under **Source**, select:
   - **GitHub Actions** (NOT "Deploy from a branch")
   
   ⚠️ **Important**: Do NOT select "Deploy from a branch" - this conflicts with the automated GitHub Actions deployment.

## 2. Push Your Changes

Make sure you've committed and pushed all the recent changes:

```bash
git add .
git commit -m "Update GitHub Pages setup instructions for Actions deployment"
git push origin main
```

## 3. Trigger the Workflow

The GitHub Actions workflow will automatically trigger when you push changes to the `dbt_divvy/` directory or the workflow file itself. You can also manually trigger it:

1. Go to **Actions** tab in your repository
2. Click on **Deploy dbt Documentation to GitHub Pages**
3. Click **Run workflow** button

## 4. Access Your Documentation

Once the workflow completes successfully (usually 2-5 minutes), your documentation will be available at:

```
https://[YOUR_USERNAME].github.io/divvybikes-share-success/
```

The site will display:
- **Welcome page** with project overview and key statistics (335K+ records, 8 models, 97% test success)
- **Direct link to dbt documentation** with interactive data lineage
- **Professional portfolio showcase** of your data engineering pipeline

## 5. Troubleshooting

### Issue: Site still shows README.md content
**Solution**: Ensure GitHub Pages source is set to **"GitHub Actions"** (not "Deploy from a branch")

### Issue: Workflow fails
**Solution**: 
1. Check the **Actions** tab for error details
2. Ensure the `docs/` directory contains all necessary files
3. Verify the workflow has proper permissions

### Issue: 404 error after deployment
**Solution**: 
1. Check that the workflow completed successfully
2. Verify GitHub Pages is enabled in repository settings
3. Wait a few minutes for DNS propagation

## 6. How the Deployment Works

The GitHub Actions workflow (`deploy-dbt-docs.yml`) automatically:

1. **Triggers** on pushes to `dbt_divvy/**` directory or workflow changes
2. **Copies** pre-built dbt documentation from `docs/` directory  
3. **Uploads** the documentation as a GitHub Pages artifact
4. **Deploys** to your GitHub Pages site with proper permissions

This approach ensures your dbt documentation is automatically updated whenever you modify your dbt project or documentation files.
