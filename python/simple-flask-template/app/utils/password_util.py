from cryptography.fernet import Fernet, InvalidToken
from os import getenv
from binascii import Error as BinAsciiError


class PasswordDecryptionError(Exception):
    """Custom exception for failed password decryption."""

    pass


def decrypt_password(encrypted_password):
    """Decrypt a password.

    Args:
        encrypted_password (str): Encrypted password.

    Raises:
        PasswordDecryptionError: Problem decrypting password.

    Returns:
        str: decrypted password

    """
    try:
        fernet_key = Fernet(get_key_from_env_variable())
        pass_as_bytes = encrypted_password.encode()
        password_decrypted = fernet_key.decrypt(pass_as_bytes).decode()
        return password_decrypted

    except (InvalidToken, BinAsciiError):
        raise PasswordDecryptionError('Incorrect key')

    except TypeError:
        raise PasswordDecryptionError('Input password should be string type')


def get_key_from_env_variable():
    """Retrieve the Fernet key used to decrypt a password.

    Should be set as an environmental variable (see key_env_var).

    Raises:
        PasswordDecryptionError: Problem decrypting password.

    Returns:
        str: Fernet key string

    """
    key_env_var = 'CRYPTO_KEY'
    key = getenv(key_env_var)

    if key is not None:
        return key
    else:
        msg = 'Unable to decrypt password: ' \
              'No {} environmental variable ' \
              'found'.format(key_env_var)
        raise PasswordDecryptionError(msg)
