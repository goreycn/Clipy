//
//  CPYFolderTableView.swift
//  Clipy
//
//  Created by 古林俊佑 on 2015/06/28.
//  Copyright (c) 2015年 Shunsuke Furubayashi. All rights reserved.
//

import Cocoa
import Realm

// MARK: - CPYFolderTableView Protocol
@objc protocol CPYFolderTableViewDelegate {
    optional func selectFolder(row: Int)
}

// MARK: - CPYFolderTableView
class CPYFolderTableView: NSTableView {

    // MARK: - Properties
    weak var tableDelegate: CPYFolderTableViewDelegate?
    private var folderIcon: NSImage?

    // MARK - Init
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setDelegate(self)
        setDataSource(self)

        registerForDraggedTypes([Constants.Common.draggedDataType])
        setDraggingSourceOperationMask(NSDragOperation.Move, forLocal: true)
    }

}

// MARK: - NSTableView DataSource
extension CPYFolderTableView: NSTableViewDataSource {
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return Int(CPYSnippetManager.sharedManager.loadFolders().count)
    }

    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        let folders = CPYSnippetManager.sharedManager.loadSortedFolders()
        if let folder = folders.objectAtIndex(UInt(row)) as? CPYFolder {
            if let dataCell = tableColumn?.dataCellForRow(row) as? CPYImageAndTextCell {
                dataCell.textColor = (folder.enable) ? .blackColor() : .lightGrayColor()
            }
            return folder.title
        }
        return ""
    }

    func tableView(tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        tableDelegate?.selectFolder?(row)
        return true
    }
}

// MARK: - NSTableView Delegate
extension CPYFolderTableView: NSTableViewDelegate {
    func tableView(tableView: NSTableView, willDisplayCell cell: AnyObject, forTableColumn tableColumn: NSTableColumn?, row: Int) {
        (cell as? CPYImageAndTextCell)?.cellImageType = .Folder
    }

    func control(control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        if let text = fieldEditor.string {
            if let tableView = control as? NSTableView where text.characters.count != 0 {
                if let folder = CPYSnippetManager.sharedManager.loadSortedFolders().objectAtIndex(UInt(tableView.selectedRow)) as? CPYFolder {
                    let realm = RLMRealm.defaultRealm()
                    realm.transaction {
                        folder.title = text
                    }
                }
                return true
            }
        }
        return false
    }

    func tableView(tableView: NSTableView, writeRowsWithIndexes rowIndexes: NSIndexSet, toPasteboard pboard: NSPasteboard) -> Bool {
        let draggedTypes = [Constants.Common.draggedDataType]
        pboard.declareTypes(draggedTypes, owner: self)

        let data = NSKeyedArchiver.archivedDataWithRootObject(rowIndexes)
        pboard.setData(data, forType: Constants.Common.draggedDataType)

        return true
    }

    func tableView(tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
        let pboard = info.draggingPasteboard()
        let draggedTypes = [Constants.Common.draggedDataType]
        let draggingSource: AnyObject? = info.draggingSource()

        if pboard.availableTypeFromArray(draggedTypes) != nil {
            if draggingSource is NSTableView {
                if dropOperation == NSTableViewDropOperation.Above {
                    return NSDragOperation.Move
                }
            }
        }

        return NSDragOperation.None
    }

    func tableView(tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {

        let pboard = info.draggingPasteboard()
        if let data = pboard.dataForType(Constants.Common.draggedDataType) {
            if let rowIndexes = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? NSIndexSet {
                if row == rowIndexes.firstIndex {
                    return false
                }
                if rowIndexes.count > 1 {
                    return false
                }

                CPYSnippetManager.sharedManager.updateFolderIndex(row, selectIndexes: rowIndexes)
                reloadData()
                if row > rowIndexes.firstIndex {
                    selectRowIndexes(NSIndexSet(index: row - 1), byExtendingSelection: false)
                    tableDelegate?.selectFolder?(row - 1)
                } else {
                    selectRowIndexes(NSIndexSet(index: row), byExtendingSelection: false)
                    tableDelegate?.selectFolder?(row)
                }

            }
        }
        return true
    }
}
