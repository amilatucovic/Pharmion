using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Pharmion.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddReservationStateMachine : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Status",
                table: "Reservations");

            migrationBuilder.AddColumn<string>(
                name: "ReservationState",
                table: "Reservations",
                type: "nvarchar(1000)",
                maxLength: 1000,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "Reservations",
                type: "datetime2",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ReservationState",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "Reservations");

            migrationBuilder.AddColumn<int>(
                name: "Status",
                table: "Reservations",
                type: "int",
                nullable: false,
                defaultValue: 0);
        }
    }
}
