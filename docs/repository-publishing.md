# Repository publishing

The checkout is a normal git repository after the initial local commit. To create or update the remote repository under the authenticated account:

```bash
./tool/publish_github.sh private
```

Use `public` instead of `private` when the source should be visible publicly. The helper requires GitHub CLI authentication and defaults to `eiranotes/Locus`. Override the target with `GITHUB_OWNER` and `GITHUB_REPOSITORY_NAME`.

When the checkout was cloned from the supplied bundle, the helper preserves that local remote as `source-bundle` and assigns the GitHub repository to `origin`.

A `.bundle` file produced with `git bundle create ... --all` contains the complete local history and can be cloned without GitHub:

```bash
git clone reality-diorama-flutter.bundle reality-diorama-flutter
```
