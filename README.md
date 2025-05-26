# Heptagon_Area_Sorting_System

## Overview

This project implements a **Verilog-based digital system** that calculates and sorts the areas of five heptagons (7-sided polygons) in real-time. The system is designed using synthesizable behavioral Verilog coding techniques and features a complete pipeline for coordinate processing, geometric calculations, and area-based sorting.

## 🎯 Project Objectives

- **Calculate areas** of multiple heptagons using the Shoelace formula
- **Sort coordinates** using cross product vector analysis for consistent ordering
- **Implement bubble sort** algorithm for area-based ranking
- **Output results** sequentially with validity indicators
- **Demonstrate** advanced digital design concepts in FPGA/ASIC development

## 🏗️ System Architecture

### Key Features
- **State Machine Design**: 10-state FSM controlling the entire processing pipeline
- **Vector Mathematics**: Cross product calculations for coordinate sorting
- **Geometric Processing**: Shoelace formula implementation for polygon area calculation
- **Sorting Algorithms**: Bubble sort for area ranking
- **Real-time Processing**: Pipelined architecture for continuous operation

### Processing Pipeline
1. **Data Input** (35 coordinate pairs for 5 heptagons)
2. **Coordinate Sorting** (using vector cross products)
3. **Area Calculation** (Shoelace formula implementation)
4. **Bubble Sort** (area-based ranking)
5. **Sequential Output** (sorted results with validity signals)

## 📊 Technical Specifications

| Signal | I/O | Width | Description |
|--------|-----|-------|-------------|
| `clk` | I | 1 | Clock signal |
| `reset` | I | 1 | Asynchronous reset (active high) |
| `X` | I | 10 | X-coordinate input (unsigned) |
| `Y` | I | 10 | Y-coordinate input (unsigned) |
| `valid` | O | 1 | Output validity indicator |
| `Index` | O | 3 | Heptagon index (1-5) |
| `Area` | O | 19 | Calculated area value |

## 🔄 Operation Flow

### Input Phase
- **35 clock cycles**: Sequential input of coordinate pairs
- **5 heptagons**: Each defined by 7 vertices
- **Coordinate buffering**: Internal storage and preprocessing

### Processing Phase
- **Cross Product Calculation**: Determines proper vertex ordering
- **Coordinate Sorting**: Ensures counterclockwise arrangement
- **Area Computation**: Uses Shoelace formula for accurate results
- **Sorting Operation**: Bubble sort ranks heptagons by area

### Output Phase
- **5 clock cycles**: Sequential output of sorted results
- **Valid signal**: Indicates when outputs are ready
- **Index + Area**: Paired output of heptagon ID and calculated area
