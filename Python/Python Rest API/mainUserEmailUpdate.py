import os
import logging
from dotenv import load_dotenv
import asyncio
import pandas as pd
from azure.identity.aio import ClientSecretCredential
from msgraph import GraphServiceClient
from kiota_abstractions.api_error import APIError
from msgraph.generated.models.user import User
from msgraph.generated.users.users_request_builder import UsersRequestBuilder
from kiota_abstractions.base_request_configuration import RequestConfiguration
from msgraph.generated.models.invitation import Invitation

load_dotenv()

TENANT_ID = os.getenv("TENANT_ID")
CLIENT_ID = os.getenv("CLIENT_ID")
CLIENT_SECRET = os.getenv("CLIENT_SECRET")
current_working_directory =  os.path.dirname(os.path.abspath(__file__))
CSV_PATH = os.path.join(current_working_directory, "GuestEmailUpdate.csv")
LoggingPath = os.path.join(current_working_directory, "app.log")
DRY_RUN = False # Set to True to simulate updates without making changes
print(f"CSV path is {CSV_PATH}")

logging.basicConfig(level=logging.INFO, format='%(asctime)s , %(levelname)s , %(message)s',
                    handlers=[logging.FileHandler(LoggingPath), logging.StreamHandler()])

logger = logging.getLogger(__name__)

async def update_guest_email():
    # authenticate
    scopes = ['https://graph.microsoft.com/.default']
    credentials = ClientSecretCredential(
    TENANT_ID,
    CLIENT_ID,
    CLIENT_SECRET,
    )
    client = GraphServiceClient(credentials=credentials, scopes=scopes)



    #read csv
    df = pd.read_csv(CSV_PATH)

    for i, row in df.iterrows():
        old_email = row['OldEmail']
        new_email = row['NewEmail']
        print(f"searching for guest {old_email} in azure portal...")

        query_params = UsersRequestBuilder.UsersRequestBuilderGetQueryParameters(
        filter = f"mail eq '{old_email}' or otherMails/any(o:o eq '{old_email}')",
        )

        request_configuration = RequestConfiguration(
        query_parameters = query_params,
        )

        try:
            result = await client.users.get(request_configuration=request_configuration)

        except APIError as e:
            print(f"Error occurred while searching for {old_email}: {e}")
            continue

        if result.value:
            user = result.value[0]
            logger.info(f"user id is {user.id}, user nanme is {user.display_name} and user email is {user.mail}")

            if DRY_RUN:
                logger.info(f"DRY RUN would update {old_email} to {new_email}")
            else:
                try:
                    await client.users.by_user_id(user.id).patch(User(mail=new_email, other_mails= [old_email, new_email]))
                    logger.info(f"updated {old_email} to {new_email}")
                except APIError as e:
                    logger.error(f"failed to update {old_email}: {e.error.message}")
        else:
            logger.warning(f"guest {old_email} not updated in azure portal")
        # send remedption invitation to new email
        request_body = Invitation(
            invited_user_email_address=new_email,
            invite_redirect_url="https://app.powerbi.com/home?ctid=1f4a5522-5f5a-4974-8d95-9a032f4cf2e5",
            send_invitation_message=True,
            invited_user=User(
            id = user.id
        ),
        reset_redemption = True,
        )

        try:
            await client.invitations.post(request_body)
            logger.info(f"Successfully sent invitation to {new_email}")
        except APIError as e:
            logger.error(f"failed to create invitation for {new_email}: {e.error.message}")


        await credentials.close()

if __name__ == "__main__":
    asyncio.run(update_guest_email())