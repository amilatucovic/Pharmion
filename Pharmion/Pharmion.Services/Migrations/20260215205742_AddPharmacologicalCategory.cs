using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Pharmion.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddPharmacologicalCategory : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "MedicationDetails",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<int>(
                name: "PharmacologicalCategoryId",
                table: "MedicationDetails",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "MedicationDetails",
                type: "datetime2",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "PharmacologicalCategory",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Code = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Name = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PharmacologicalCategory", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_MedicationDetails_PharmacologicalCategoryId",
                table: "MedicationDetails",
                column: "PharmacologicalCategoryId");

            migrationBuilder.AddForeignKey(
                name: "FK_MedicationDetails_PharmacologicalCategory_PharmacologicalCategoryId",
                table: "MedicationDetails",
                column: "PharmacologicalCategoryId",
                principalTable: "PharmacologicalCategory",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_MedicationDetails_PharmacologicalCategory_PharmacologicalCategoryId",
                table: "MedicationDetails");

            migrationBuilder.DropTable(
                name: "PharmacologicalCategory");

            migrationBuilder.DropIndex(
                name: "IX_MedicationDetails_PharmacologicalCategoryId",
                table: "MedicationDetails");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "MedicationDetails");

            migrationBuilder.DropColumn(
                name: "PharmacologicalCategoryId",
                table: "MedicationDetails");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "MedicationDetails");
        }
    }
}
