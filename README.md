# Trust Nepal - Escrow

A secure and reliable Escrow service platform tailored for the Nepal market. This project provides a safe way for buyers and sellers to conduct transactions, ensuring that funds are only released when all parties are satisfied.

## Project Structure

This is a monorepo containing the following components:

- **`frontend/`**: The Flutter-based mobile application for users.
- **`backend/`**: The Node.js/Express backend server providing the API and business logic.
- **`admin-web/`**: A web-based dashboard for administrators to manage transactions and disputes.
- **`infra/`**: Infrastructure configuration and deployment scripts (Docker, etc.).
- **`docs/`**: Project documentation and architecture diagrams.

## Key Features

- **Secure Payments**: Integration with local payment gateways (eSewa, etc.).
- **Transaction Tracking**: Real-time status updates for both buyers and sellers.
- **Dispute Resolution**: A robust system for handling conflicts through administrative intervention.
- **Notification System**: Automated alerts for all transaction milestones.

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Node.js](https://nodejs.org/) (v18+)
- [Docker](https://www.docker.com/) (optional, for local development)
- [pnpm](https://pnpm.io/) (for workspace management)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/iamdhruba/Trust-Nepal---Escrow.git
   cd Trust-Nepal---Escrow
   ```

2. **Install dependencies:**
   ```bash
   pnpm install
   ```

3. **Configure environment variables:**
   - Copy `.env.example` to `.env` in the `backend/` directory and fill in your secrets.
   - Set up your Firebase project and add `google-services.json` to `frontend/android/app/`.

### Running Locally

#### Backend
```bash
cd backend
npm run dev
```

#### Frontend
```bash
cd frontend
flutter run
```

## Deployment

Refer to the `infra/` directory for deployment instructions using Docker and other cloud providers.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
