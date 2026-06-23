using System;
using System.Data;
using Microsoft.Data.SqlClient;

namespace UPCommon.Connection
{
    public class DatabaseConnection
    {
        private readonly string _connectionString;
        private readonly string _appRoleName;
        private readonly string _appRolePassword;

        // Konstruktor sada prima i podatke o aplikacionoj ulozi
        public DatabaseConnection(string connectionString, string appRoleName, string appRolePassword)
        {
            if (string.IsNullOrWhiteSpace(connectionString))
            {
                throw new ArgumentException("Connection string ne moze biti prazan.", nameof(connectionString));
            }
            _connectionString = connectionString;
            _appRoleName = appRoleName;
            _appRolePassword = appRolePassword;
        }

        // Pomocna metoda koja otvara konekciju i ODMAH aktivira Application Role sa svojom lozinkom
        private SqlConnection OtvoriIAutorizujKonekciju()
        {
            var connection = new SqlConnection(_connectionString);
            connection.Open();

            // Aktivacija aplikacione uloge uz eksplicitno definisanje parametara
            using (var command = new SqlCommand("sys.sp_setapprole", connection))
            {
                command.CommandType = CommandType.StoredProcedure;

                // Eksplicitno definisanje tipa i duzine parametara za sp_setapprole
                SqlParameter paramRole = new SqlParameter("@rolename", SqlDbType.VarChar, 128) { Value = _appRoleName };
                SqlParameter paramPass = new SqlParameter("@password", SqlDbType.VarChar, 128) { Value = _appRolePassword };

                command.Parameters.Add(paramRole);
                command.Parameters.Add(paramPass);

                command.ExecuteNonQuery();
            }

            return connection;
        }

        public bool TestConnection()
        {
            try
            {
                using (var connection = OtvoriIAutorizujKonekciju())
                {
                    return true;
                }
            }
            catch (SqlException ex)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"SQL Greška pri povezivanju: {ex.Message} (Kod: {ex.Number})");
                Console.ResetColor();
                return false;
            }
        }

        public void ExecuteNonQueryProcedure(string procedureName, SqlParameter[] parameters = null)
        {
            // Umesto 'new SqlConnection' i 'connection.Open()', sada pozivamo nasu metodu
            using (var connection = OtvoriIAutorizujKonekciju())
            {
                using (var command = new SqlCommand(procedureName, connection))
                {
                    command.CommandType = CommandType.StoredProcedure;

                    if (parameters != null)
                    {
                        command.Parameters.AddRange(parameters);
                    }

                    command.ExecuteNonQuery();
                }
            }
        }

        public DataTable ExecuteReader(string query, CommandType commandType = CommandType.Text, SqlParameter[] parameters = null)
        {
            var dataTable = new DataTable();

            using (var connection = OtvoriIAutorizujKonekciju())
            {
                using (var command = new SqlCommand(query, connection))
                {
                    command.CommandType = commandType;

                    if (parameters != null)
                    {
                        command.Parameters.AddRange(parameters);
                    }

                    using (var adapter = new SqlDataAdapter(command))
                    {
                        adapter.Fill(dataTable);
                    }
                }
            }

            return dataTable;
        }

        public object ExecuteScalar(string query, CommandType commandType = CommandType.Text, SqlParameter[] parameters = null)
        {
            using (var connection = OtvoriIAutorizujKonekciju())
            {
                using (var command = new SqlCommand(query, connection))
                {
                    command.CommandType = commandType;

                    if (parameters != null)
                    {
                        command.Parameters.AddRange(parameters);
                    }

                    return command.ExecuteScalar();
                }
            }
        }
    }
}