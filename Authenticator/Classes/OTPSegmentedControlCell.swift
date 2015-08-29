//
//  OTPSegmentedControlCell.swift
//  Authenticator
//
//  Copyright (c) 2014 Matt Rubin
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import UIKit

protocol SegmentedControlRowModel {
    var segments: [(title: String, value: Int)] { get }
    var initialValue: Int { get }
}

class OTPSegmentedControlCell: UITableViewCell {
    private let segmentedControl = UISegmentedControl()
    private var values: [Int] = []

    var value: Int {
        return values[segmentedControl.selectedSegmentIndex]
    }

    // MARK: - Init

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureSubviews()
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureSubviews()
    }

    // MARK: - Subviews

    private func configureSubviews() {
        contentView.addSubview(segmentedControl)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        segmentedControl.frame = CGRectMake(20, 15, CGRectGetWidth(contentView.bounds) - 40, 29)
    }

    // MARK: - Update

    func updateWithRowModel(rowModel: SegmentedControlRowModel) {
        // Remove any old segments
        segmentedControl.removeAllSegments()
        // Add new segments
        for i in rowModel.segments.startIndex ..< rowModel.segments.endIndex {
            let segment = rowModel.segments[i]
            segmentedControl.insertSegmentWithTitle(segment.title, atIndex: i, animated: false)
        }
        // Store values
        values = rowModel.segments.map { $0.value }
        // Select the initial value
        segmentedControl.selectedSegmentIndex = find(values, rowModel.initialValue) ?? 0

    }
}