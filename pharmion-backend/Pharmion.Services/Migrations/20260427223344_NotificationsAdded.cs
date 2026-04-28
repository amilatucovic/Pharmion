using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Pharmion.Services.Migrations
{
    /// <inheritdoc />
    public partial class NotificationsAdded : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "TherapyReminders");

            migrationBuilder.DropTable(
                name: "TherapyScheduleTimes");

            migrationBuilder.DropTable(
                name: "TherapySchedules");

            migrationBuilder.DropColumn(
                name: "Status",
                table: "Notifications");

            migrationBuilder.RenameColumn(
                name: "SentAt",
                table: "Notifications",
                newName: "ReadAt");

            migrationBuilder.AddColumn<bool>(
                name: "IsRead",
                table: "Notifications",
                type: "bit",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsRead",
                table: "Notifications");

            migrationBuilder.RenameColumn(
                name: "ReadAt",
                table: "Notifications",
                newName: "SentAt");

            migrationBuilder.AddColumn<int>(
                name: "Status",
                table: "Notifications",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateTable(
                name: "TherapySchedules",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    PatientId = table.Column<int>(type: "int", nullable: false),
                    PrescriptionItemId = table.Column<int>(type: "int", nullable: true),
                    ProductId = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    DoseText = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    EndDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    InstructionText = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    StartDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TherapySchedules", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TherapySchedules_Patients_PatientId",
                        column: x => x.PatientId,
                        principalTable: "Patients",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_TherapySchedules_PrescriptionItems_PrescriptionItemId",
                        column: x => x.PrescriptionItemId,
                        principalTable: "PrescriptionItems",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_TherapySchedules_Products_ProductId",
                        column: x => x.ProductId,
                        principalTable: "Products",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "TherapyReminders",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    TherapyScheduleId = table.Column<int>(type: "int", nullable: false),
                    AcknowledgedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    ScheduledFor = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Status = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TherapyReminders", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TherapyReminders_TherapySchedules_TherapyScheduleId",
                        column: x => x.TherapyScheduleId,
                        principalTable: "TherapySchedules",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TherapyScheduleTimes",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    TherapyScheduleId = table.Column<int>(type: "int", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    TimeOfDay = table.Column<TimeSpan>(type: "time", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TherapyScheduleTimes", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TherapyScheduleTimes_TherapySchedules_TherapyScheduleId",
                        column: x => x.TherapyScheduleId,
                        principalTable: "TherapySchedules",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_TherapyReminders_TherapyScheduleId_ScheduledFor",
                table: "TherapyReminders",
                columns: new[] { "TherapyScheduleId", "ScheduledFor" });

            migrationBuilder.CreateIndex(
                name: "IX_TherapySchedules_PatientId",
                table: "TherapySchedules",
                column: "PatientId");

            migrationBuilder.CreateIndex(
                name: "IX_TherapySchedules_PrescriptionItemId",
                table: "TherapySchedules",
                column: "PrescriptionItemId");

            migrationBuilder.CreateIndex(
                name: "IX_TherapySchedules_ProductId",
                table: "TherapySchedules",
                column: "ProductId");

            migrationBuilder.CreateIndex(
                name: "IX_TherapyScheduleTimes_TherapyScheduleId",
                table: "TherapyScheduleTimes",
                column: "TherapyScheduleId");
        }
    }
}
