# Wallet App

A centralized wallet application that allows users to manage their digital wallets, make transfers, and track transactions.

## Technical Stack

- Ruby 3.3.0
- Rails 8.0.2
- PostgreSQL 15
- Docker & Docker Compose

## Key Design Decisions

1. **Authentication**: Using JWT tokens for API authentication
2. **Transaction Management**: 
   - ACID compliance using database transactions
   - Optimistic locking for concurrent operations
   - Status tracking for transaction states
   - Service object pattern for encapsulating business logic
3. **Error Handling**: Comprehensive error handling with descriptive messages and proper status codes
4. **Testing**: RSpec for unit and integration tests

## Setup and Running

1. Ensure you have Docker and Docker Compose installed
2. Run `./setup.sh` to:
   - Build and start containers
   - Setup database
   - Run migrations
   - Seed test data
   - Start the server

The API will be available at http://localhost:3000

## Testing

To run the test suite:

1. Access the web container:
   ```bash
   docker exec -it wallet_app-web-1 bash
   ```

2. Run the test suite:
   ```bash
   bundle exec rspec spec
   ```

This will run all 63 tests covering:
- Transaction Service (26 tests)
- Wallets Controller (37 tests)
- Model validations and relationships

## API Documentation

### Authentication
All endpoints require a JWT token in the Authorization header:
```
Authorization: Bearer <token>
```

Test tokens are provided in the seed output after setup.

### Making API Requests

You can interact with the API using either cURL or using an HTTP client like Postman:

#### Example using cURL

```bash
# Check Balance
curl -X GET http://localhost:3000/api/v1/wallets/balance \
  -H "Authorization: Bearer <your_token>"

# Deposit Money
curl -X POST http://localhost:3000/api/v1/wallets/deposit \
  -H "Authorization: Bearer <your_token>" \
  -H "Content-Type: application/json" \
  -d '{"amount": 100}'

# Withdraw Money
curl -X POST http://localhost:3000/api/v1/wallets/withdraw \
  -H "Authorization: Bearer <your_token>" \
  -H "Content-Type: application/json" \
  -d '{"amount": 50}'

# Transfer Money
curl -X POST http://localhost:3000/api/v1/wallets/transfer \
  -H "Authorization: Bearer <your_token>" \
  -H "Content-Type: application/json" \
  -d '{"amount": 30, "receiver_id": 2}'

# Get Transaction History
curl -X GET http://localhost:3000/api/v1/wallets/transactions \
  -H "Authorization: Bearer <your_token>"
```

### Endpoints

1. **Check Balance**
   ```
   GET /api/v1/wallets/balance
   ```

2. **Deposit Money**
   ```
   POST /api/v1/wallets/deposit
   {
     "amount": 100
   }
   ```

3. **Withdraw Money**
   ```
   POST /api/v1/wallets/withdraw
   {
     "amount": 50
   }
   ```

4. **Transfer Money**
   ```
   POST /api/v1/wallets/transfer
   {
     "amount": 30,
     "receiver_id": 2
   }
   ```

5. **Transaction History**
   ```
   GET /api/v1/wallets/transactions
   ```

## Development Time

Total time: ~12 hours
- Morning~ Research and planning, learning about wallet systems and crypto wallet implementations
- Afternoon~ Core implementation of models, controllers, services, testing, dockerization, and documentation

## Features Not Implemented (Areas for Improvement)

- Implement proper user session management
- Basic CORS configuration
- Database indexes for frequent queries
- Add pagination for transaction history
- Process transfers in background jobs (using Sidekiq)
- Basic rate limiting for API endpoints
- Multiple wallets per user (multi-currency support)
