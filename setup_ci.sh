#!/bin/bash
# filepath: c:\Project\AI_chat_bot\setup_ci.sh

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}AI Chat Bot CI/CD Setup Script${NC}"
echo -e "${BLUE}============================${NC}"
echo

echo -e "${YELLOW}This script will help you set up CI/CD for the AI Chat Bot project.${NC}"
echo -e "${YELLOW}It will check for required dependencies and guide you through setup.${NC}"
echo

# Check for required tools
echo -e "${BLUE}Checking for required tools...${NC}"

# Check for Flutter
if command -v flutter >/dev/null 2>&1; then
    flutter_version=$(flutter --version | head -1)
    echo -e "${GREEN}✓ Flutter is installed: $flutter_version${NC}"
else
    echo -e "${RED}✗ Flutter is not installed. Please install Flutter 3.29.1 or higher.${NC}"
    echo -e "${YELLOW}Visit https://flutter.dev/docs/get-started/install for installation instructions.${NC}"
    exit 1
fi

# Check for Firebase CLI
if command -v firebase >/dev/null 2>&1; then
    firebase_version=$(firebase --version)
    echo -e "${GREEN}✓ Firebase CLI is installed: $firebase_version${NC}"
else
    echo -e "${RED}✗ Firebase CLI is not installed.${NC}"
    echo -e "${YELLOW}Installing Firebase CLI...${NC}"
    npm install -g firebase-tools
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install Firebase CLI. Please install it manually:${NC}"
        echo -e "${YELLOW}npm install -g firebase-tools${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ Firebase CLI installed successfully.${NC}"
    fi
fi

# Check for GitHub CLI
if command -v gh >/dev/null 2>&1; then
    gh_version=$(gh --version | head -1)
    echo -e "${GREEN}✓ GitHub CLI is installed: $gh_version${NC}"
else
    echo -e "${YELLOW}⚠ GitHub CLI is not installed. It's recommended for setting up GitHub Secrets.${NC}"
    echo -e "${YELLOW}Visit https://cli.github.com/ for installation instructions.${NC}"
fi

echo
echo -e "${BLUE}Setting up Firebase project...${NC}"
echo -e "${YELLOW}Please log in to Firebase:${NC}"
firebase login
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to log in to Firebase. Please try again later.${NC}"
    exit 1
fi

echo
echo -e "${BLUE}Linking Firebase project...${NC}"
echo -e "${YELLOW}Using project ID: vinh-aff13${NC}"
firebase use vinh-aff13
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to set Firebase project. Please check if you have access to this project.${NC}"
    exit 1
fi

echo
echo -e "${BLUE}Setting up GitHub repository...${NC}"
if command -v gh >/dev/null 2>&1; then
    echo -e "${YELLOW}Do you want to set up GitHub Secrets now? (y/n)${NC}"
    read -r setup_secrets
    if [[ $setup_secrets =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Please log in to GitHub:${NC}"
        gh auth login
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to log in to GitHub. Skipping secret setup.${NC}"
        else
            echo -e "${YELLOW}Getting Firebase service account key...${NC}"
            echo -e "${YELLOW}Please follow these steps manually:${NC}"
            echo -e "1. Go to Firebase Console > Project Settings > Service Accounts"
            echo -e "2. Generate and download a new private key"
            echo -e "3. Save the file and provide the path below"
            
            echo -e "${YELLOW}Enter the path to your service account key file:${NC}"
            read -r service_account_key_path
            
            if [ -f "$service_account_key_path" ]; then
                echo -e "${YELLOW}Setting up GitHub secret FIREBASE_SERVICE_ACCOUNT_VINH_AFF13...${NC}"
                gh secret set FIREBASE_SERVICE_ACCOUNT_VINH_AFF13 < "$service_account_key_path"
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}✓ GitHub secret set successfully.${NC}"
                else
                    echo -e "${RED}Failed to set GitHub secret.${NC}"
                fi
            else
                echo -e "${RED}File not found. Skipping secret setup.${NC}"
            fi
        fi
    fi
else
    echo -e "${YELLOW}To set up GitHub Secrets, please:${NC}"
    echo -e "1. Go to your GitHub repository > Settings > Secrets and Variables > Actions"
    echo -e "2. Create a new secret named FIREBASE_SERVICE_ACCOUNT_VINH_AFF13"
    echo -e "3. Paste the contents of your Firebase service account key JSON file"
fi

echo
echo -e "${GREEN}CI/CD setup completed!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Push your code to GitHub"
echo -e "2. Check GitHub Actions tab to see your workflows running"
echo -e "3. For more details, refer to docs/ci_cd_setup_guide.md"
echo
