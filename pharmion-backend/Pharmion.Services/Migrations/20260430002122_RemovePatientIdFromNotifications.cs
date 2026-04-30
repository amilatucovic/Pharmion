using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Pharmion.Services.Migrations
{
    /// <inheritdoc />
    public partial class RemovePatientIdFromNotifications : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Notifications_Patients_PatientId",
                table: "Notifications");

            migrationBuilder.DropIndex(
                name: "IX_Notifications_PatientId",
                table: "Notifications");

            migrationBuilder.DropColumn(
                name: "PatientId",
                table: "Notifications");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "PatientId",
                table: "Notifications",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_PatientId",
                table: "Notifications",
                column: "PatientId");

            migrationBuilder.AddForeignKey(
                name: "FK_Notifications_Patients_PatientId",
                table: "Notifications",
                column: "PatientId",
                principalTable: "Patients",
                principalColumn: "Id");
        }
    }
}
