import os
import pandas as pd
import snowflake.connector
from datetime import datetime
from snowflake.connector.pandas_tools import write_pandas
import dotenv

dotenv.load_dotenv()

def load_csv_to_snowflake():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    csv_path = os.path.join(base_dir, "..", "data", "real-estate-raw.csv")

    print(f"[*] Lecture du fichier CSV : {csv_path}")
    if not os.path.exists(csv_path):
        raise FileNotFoundError(f"Le fichier CSV n'a pas été trouvé à l'emplacement : {csv_path}")

    df = pd.read_csv(csv_path, dtype=str)
    df['LOAD_TIMESTAMP'] = datetime.now()
    df.columns = [col.upper() for col in df.columns]

    db_name = os.getenv("SNOWFLAKE_DATABASE", "REAL_ESTATE_DB")
    schema_name = "BRONZE"   # forcé en dur, plus de dépendance au .env
    table_name = "RAW_LISTINGS"

    print("[*] Connexion à Snowflake...")
    conn = snowflake.connector.connect(
        user=os.getenv("SNOWFLAKE_USER"),
        password=os.getenv("SNOWFLAKE_PASSWORD"),
        account=os.getenv("SNOWFLAKE_ACCOUNT"),
        warehouse=os.getenv("SNOWFLAKE_WAREHOUSE", "COMPUTE_WH"),
        role=os.getenv("SNOWFLAKE_ROLE", "ACCOUNTADMIN"),
    )

    try:
        cur = conn.cursor()

        print(f"[*] Création de la base '{db_name}' si besoin...")
        cur.execute(f"CREATE DATABASE IF NOT EXISTS {db_name}")

        print(f"[*] Création du schéma '{schema_name}' si besoin...")
        cur.execute(f"CREATE SCHEMA IF NOT EXISTS {db_name}.{schema_name}")

        cur.execute(f"USE DATABASE {db_name}")
        cur.execute(f"USE SCHEMA {schema_name}")

        # Vérification : on liste les schémas pour confirmer que BRONZE existe
        cur.execute(f"SHOW SCHEMAS LIKE '{schema_name}' IN DATABASE {db_name}")
        result = cur.fetchall()
        if result:
            print(f"[+] Schéma confirmé existant : {db_name}.{schema_name}")
        else:
            print(f"[!] ATTENTION : le schéma {schema_name} n'apparaît pas après création !")

        print(f"[*] Chargement de {len(df)} lignes dans {db_name}.{schema_name}.{table_name}...")
        success, nchunks, nrows, _ = write_pandas(
            conn=conn,
            df=df,
            table_name=table_name,
            database=db_name,
            schema=schema_name,
            auto_create_table=True,
            overwrite=False
        )

        if success:
            print(f"[+] Succès ! {nrows} lignes chargées dans Snowflake.")
        else:
            raise Exception("Le chargement a échoué.")

    except Exception as e:
        print(f"[-] Erreur lors du chargement : {str(e)}")
        raise e
    finally:
        conn.close()
        print("[*] Connexion Snowflake fermée.")

if __name__ == "__main__":
    load_csv_to_snowflake()