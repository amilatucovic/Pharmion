using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Pharmion.Services.Migrations
{
    /// <inheritdoc />
    public partial class UpdatePharmacologicalCategoryRelationships : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_MedicationDetails_PharmacologicalCategory_PharmacologicalCategoryId",
                table: "MedicationDetails");

            migrationBuilder.DropPrimaryKey(
                name: "PK_PharmacologicalCategory",
                table: "PharmacologicalCategory");

            migrationBuilder.RenameTable(
                name: "PharmacologicalCategory",
                newName: "PharmacologicalCategories");

            migrationBuilder.AddPrimaryKey(
                name: "PK_PharmacologicalCategories",
                table: "PharmacologicalCategories",
                column: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_MedicationDetails_PharmacologicalCategories_PharmacologicalCategoryId",
                table: "MedicationDetails",
                column: "PharmacologicalCategoryId",
                principalTable: "PharmacologicalCategories",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_MedicationDetails_PharmacologicalCategories_PharmacologicalCategoryId",
                table: "MedicationDetails");

            migrationBuilder.DropPrimaryKey(
                name: "PK_PharmacologicalCategories",
                table: "PharmacologicalCategories");

            migrationBuilder.RenameTable(
                name: "PharmacologicalCategories",
                newName: "PharmacologicalCategory");

            migrationBuilder.AddPrimaryKey(
                name: "PK_PharmacologicalCategory",
                table: "PharmacologicalCategory",
                column: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_MedicationDetails_PharmacologicalCategory_PharmacologicalCategoryId",
                table: "MedicationDetails",
                column: "PharmacologicalCategoryId",
                principalTable: "PharmacologicalCategory",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }
    }
}
