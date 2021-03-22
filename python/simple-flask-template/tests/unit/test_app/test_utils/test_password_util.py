from unittest.mock import patch

from cryptography.fernet import Fernet
from pytest import raises

from app.utils.password_util import (get_key_from_env_variable,
                                     PasswordDecryptionError,
                                     decrypt_password)


@patch('app.utils.password_util.getenv')
def test_get_key_from_env_variable_returns_value(mock_getenv):
    # Arrange
    mock_getenv.return_value = 'thisisthekey123'

    # Act
    key = get_key_from_env_variable()

    # Assert
    assert key == 'thisisthekey123'


@patch('app.utils.password_util.getenv')
def test_get_key_from_env_variable_raises_passworddecryptioncrror_for_missing_env_var(mock_getenv):
    # Arrange
    mock_getenv.return_value = None

    # Act/assert
    with raises(PasswordDecryptionError) as e:

        get_key_from_env_variable()

        # Assert exception message
        assert e == 'Unable to decrypt password: No SECTION_A_KEY environmental variable found'


@patch('app.utils.password_util.get_key_from_env_variable')
def test_decrypt_password(mock_key):
    # Arrange - Generate key and encrypt a string
    key = Fernet.generate_key()
    mock_key.return_value = key.decode()

    fernet = Fernet(key)
    password = 'amazing_password123'
    encrypted_password = fernet.encrypt(password.encode())

    # Act - decrypt
    decrypted_pw = decrypt_password(encrypted_password.decode())

    # Assert
    assert decrypted_pw == password


@patch('app.utils.password_util.get_key_from_env_variable')
def test_decrypt_password_raises_passworddecryptionerror_with_incorrect_key(mock_key):
    # Arrange - Generate key and encrypt a string
    key = Fernet.generate_key()
    other_key = Fernet.generate_key().decode()
    mock_key.return_value = other_key

    fernet = Fernet(key)
    password = 'amazing_password123'
    encrypted_password = fernet.encrypt(password.encode())

    # Act/assert
    with raises(PasswordDecryptionError) as e:
        decrypt_password(encrypted_password.decode())

        assert e == 'Incorrect key'


@patch('app.utils.password_util.get_key_from_env_variable')
def test_decrypt_password_raises_passworddecryptionerror_with_bad_input_password(_):
    # Act/assert
    with raises(PasswordDecryptionError) as e:
        decrypt_password(b'shouldnotbeencoded')

        assert e == 'Input password should be string type'
